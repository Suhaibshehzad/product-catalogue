/**
 * Our product contract. Adapters map their source's shape into this,
 * so clients never depend on a particular data provider.
 */
export interface Category {
  slug: string;
  name: string;
}

export interface Product {
  /** Opaque string so future sources with non-numeric IDs fit without a contract change. */
  id: string;
  title: string;
  description: string;
  price: { amount: number; currency: string };
  imageUrl: string;
  category: Category;
  rating: { average: number; count: number };
}

export function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/['’]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
