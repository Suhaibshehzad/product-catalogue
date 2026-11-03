import { z } from 'zod';
import { AppError } from '../domain/errors.js';
import { slugify, type Category, type Product } from '../domain/product.js';
import { matchesAllTerms, searchTerms } from '../domain/search.js';
import type { ProductQuery, ProductSource } from '../ports/product-source.js';

const fakeStoreProduct = z.object({
  id: z.number(),
  title: z.string(),
  price: z.number(),
  description: z.string(),
  category: z.string(),
  image: z.string(),
  rating: z.object({ rate: z.number(), count: z.number() }).optional(),
});
type FakeStoreProduct = z.infer<typeof fakeStoreProduct>;

export interface FakeStoreOptions {
  baseUrl: string;
  cacheTtlMs: number;
  timeoutMs?: number;
  fetchFn?: typeof fetch;
  now?: () => number;
}

/**
 * Fake Store returns the full catalogue (20 items) in one call, so we fetch it
 * once, cache it, and filter in memory. A real source would push filtering down.
 */
export class FakeStoreProductSource implements ProductSource {
  private cache?: { products: Product[]; expiresAt: number };
  private inFlight?: Promise<Product[]>;

  constructor(private readonly options: FakeStoreOptions) {}

  async listProducts(query: ProductQuery = {}): Promise<Product[]> {
    let products = await this.allProducts();
    if (query.categorySlug) {
      products = products.filter((p) => p.category.slug === query.categorySlug);
    }
    if (query.text) {
      const terms = searchTerms(query.text);
      products = products.filter((p) => matchesAllTerms(p, terms));
    }
    return products;
  }

  async getProduct(id: string): Promise<Product | null> {
    const products = await this.allProducts();
    return products.find((p) => p.id === id) ?? null;
  }

  async listCategories(): Promise<Category[]> {
    const products = await this.allProducts();
    const bySlug = new Map(products.map((p) => [p.category.slug, p.category]));
    return [...bySlug.values()].sort((a, b) => a.name.localeCompare(b.name));
  }

  private async allProducts(): Promise<Product[]> {
    const now = (this.options.now ?? Date.now)();
    if (this.cache && this.cache.expiresAt > now) return this.cache.products;

    // Share one upstream request between concurrent callers.
    this.inFlight ??= this.fetchProducts()
      .then((products) => {
        this.cache = { products, expiresAt: now + this.options.cacheTtlMs };
        return products;
      })
      .finally(() => {
        this.inFlight = undefined;
      });
    return this.inFlight;
  }

  private async fetchProducts(): Promise<Product[]> {
    const fetchFn = this.options.fetchFn ?? fetch;
    const url = new URL('/products', this.options.baseUrl);
    let body: unknown;
    try {
      const res = await fetchFn(url, { signal: AbortSignal.timeout(this.options.timeoutMs ?? 5000) });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      body = await res.json();
    } catch (cause) {
      throw new AppError('UPSTREAM_UNAVAILABLE', 'Product data source is unavailable', { cause });
    }

    const parsed = z.array(fakeStoreProduct).safeParse(body);
    if (!parsed.success) {
      throw new AppError('UPSTREAM_UNAVAILABLE', 'Product data source returned unexpected data', {
        cause: parsed.error,
      });
    }
    return parsed.data.map(toProduct);
  }
}

function toProduct(p: FakeStoreProduct): Product {
  return {
    id: String(p.id),
    title: p.title,
    description: p.description,
    price: { amount: p.price, currency: 'USD' },
    imageUrl: p.image,
    category: { slug: slugify(p.category), name: p.category },
    rating: { average: p.rating?.rate ?? 0, count: p.rating?.count ?? 0 },
  };
}
