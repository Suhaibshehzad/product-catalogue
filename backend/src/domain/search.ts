import type { Product } from './product.js';

export function searchTerms(text: string): string[] {
  return text.toLowerCase().split(/\s+/).filter(Boolean);
}

/** True when every term appears in the product's title, description or category name. */
export function matchesAllTerms(product: Product, terms: string[]): boolean {
  const haystack = `${product.title} ${product.description} ${product.category.name}`.toLowerCase();
  return terms.every((term) => haystack.includes(term));
}
