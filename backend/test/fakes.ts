import type { Enquiry } from '../src/domain/enquiry.js';
import { slugify, type Category, type Product } from '../src/domain/product.js';
import { matchesAllTerms, searchTerms } from '../src/domain/search.js';
import type { EnquiryNotifier } from '../src/ports/enquiry-notifier.js';
import type { ProductQuery, ProductSource } from '../src/ports/product-source.js';

export function product(overrides: Partial<Product> & { id: string; categoryName?: string }): Product {
  const { categoryName = 'electronics', ...rest } = overrides;
  return {
    title: `Product ${overrides.id}`,
    description: 'A product',
    price: { amount: 10, currency: 'USD' },
    imageUrl: `https://img.example/${overrides.id}.png`,
    category: { slug: slugify(categoryName), name: categoryName },
    rating: { average: 3, count: 10 },
    ...rest,
  };
}

export class InMemoryProductSource implements ProductSource {
  constructor(public products: Product[]) {}

  async listProducts(query: ProductQuery = {}): Promise<Product[]> {
    const terms = searchTerms(query.text ?? '');
    return this.products
      .filter((p) => !query.categorySlug || p.category.slug === query.categorySlug)
      .filter((p) => matchesAllTerms(p, terms));
  }

  async getProduct(id: string): Promise<Product | null> {
    return this.products.find((p) => p.id === id) ?? null;
  }

  async listCategories(): Promise<Category[]> {
    return [...new Map(this.products.map((p) => [p.category.slug, p.category])).values()];
  }
}

export class RecordingNotifier implements EnquiryNotifier {
  sent: Enquiry[] = [];
  failWith?: Error;

  async notify(enquiry: Enquiry): Promise<void> {
    if (this.failWith) throw this.failWith;
    this.sent.push(enquiry);
  }
}

export const catalogueFixture = (): Product[] => [
  product({ id: '1', title: 'Slim Fit Cotton Shirt', categoryName: "men's clothing", rating: { average: 4.1, count: 50 } }),
  product({ id: '2', title: 'Casual Jacket', categoryName: "men's clothing", rating: { average: 4.7, count: 500 } }),
  product({ id: '3', title: 'Gold Ring', categoryName: 'jewelery', description: 'Solid gold', rating: { average: 3.9, count: 70 } }),
  product({ id: '4', title: 'SSD 1TB', categoryName: 'electronics', description: 'Fast solid state drive', rating: { average: 4.8, count: 300 } }),
  product({ id: '5', title: 'Monitor 27"', categoryName: 'electronics', rating: { average: 2.9, count: 250 } }),
  product({ id: '6', title: 'USB Hard Drive', categoryName: 'electronics', rating: { average: 3.3, count: 200 } }),
  product({ id: '7', title: 'Wireless Mouse', categoryName: 'electronics', rating: { average: 4.8, count: 900 } }),
];
