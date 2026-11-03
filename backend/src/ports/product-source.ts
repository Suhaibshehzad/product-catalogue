import type { Category, Product } from '../domain/product.js';

export interface ProductQuery {
  categorySlug?: string;
  /** Free-text search; every whitespace-separated term must match. */
  text?: string;
}

/**
 * Where product data comes from. Filtering lives here (not in services)
 * so a future source — a database or search index — can do it natively.
 */
export interface ProductSource {
  listProducts(query?: ProductQuery): Promise<Product[]>;
  getProduct(id: string): Promise<Product | null>;
  listCategories(): Promise<Category[]>;
}
