import { notFound } from '../domain/errors.js';
import type { Category, Product } from '../domain/product.js';
import type { ProductSource } from '../ports/product-source.js';

export interface CategoryPage {
  category: Category;
  topRated: Product[];
  others: Product[];
}

export interface CatalogueServiceOptions {
  /** Owner-curated product IDs for the home page, in display order. */
  featuredProductIds: string[];
  /** How many highest-rated products to highlight per category. */
  categoryTopRatedCount: number;
}

export class CatalogueService {
  constructor(
    private readonly source: ProductSource,
    private readonly options: CatalogueServiceOptions,
    private readonly onMissingFeatured: (id: string) => void = () => {},
  ) {}

  async featuredProducts(): Promise<Product[]> {
    const products = await Promise.all(
      this.options.featuredProductIds.map((id) => this.source.getProduct(id)),
    );
    // A curated ID that no longer exists should not break the home page.
    return products.filter((p, i): p is Product => {
      if (!p) this.onMissingFeatured(this.options.featuredProductIds[i]!);
      return p !== null;
    });
  }

  listCategories(): Promise<Category[]> {
    return this.source.listCategories();
  }

  async categoryPage(slug: string): Promise<CategoryPage> {
    const category = (await this.source.listCategories()).find((c) => c.slug === slug);
    if (!category) throw notFound('Category');

    const products = await this.source.listProducts({ categorySlug: slug });
    const ranked = [...products].sort(
      (a, b) => b.rating.average - a.rating.average || b.rating.count - a.rating.count,
    );
    const topRated = ranked.slice(0, this.options.categoryTopRatedCount);
    const topIds = new Set(topRated.map((p) => p.id));
    return { category, topRated, others: products.filter((p) => !topIds.has(p.id)) };
  }

  search(text: string): Promise<Product[]> {
    return this.source.listProducts({ text });
  }

  async product(id: string): Promise<Product> {
    const product = await this.source.getProduct(id);
    if (!product) throw notFound('Product');
    return product;
  }
}
