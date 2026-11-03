import { describe, expect, it } from 'vitest';
import { CatalogueService } from '../src/services/catalogue-service.js';
import { catalogueFixture, InMemoryProductSource } from './fakes.js';

const build = (featuredProductIds = ['4', '1', '3']) => {
  const missing: string[] = [];
  const service = new CatalogueService(
    new InMemoryProductSource(catalogueFixture()),
    { featuredProductIds, categoryTopRatedCount: 3 },
    (id) => missing.push(id),
  );
  return { service, missing };
};

describe('featuredProducts', () => {
  it('returns the owner-chosen products in the configured order', async () => {
    const { service } = build(['4', '1', '3']);
    const ids = (await service.featuredProducts()).map((p) => p.id);
    expect(ids).toEqual(['4', '1', '3']);
  });

  it('skips and reports IDs that no longer exist instead of failing the page', async () => {
    const { service, missing } = build(['4', '999', '1']);
    const ids = (await service.featuredProducts()).map((p) => p.id);
    expect(ids).toEqual(['4', '1']);
    expect(missing).toEqual(['999']);
  });
});

describe('categoryPage', () => {
  it('splits products into the top 3 by rating and the rest', async () => {
    const { service } = build();
    const page = await service.categoryPage('electronics');

    expect(page.category).toEqual({ slug: 'electronics', name: 'electronics' });
    // 7 and 4 tie on 4.8; more ratings wins.
    expect(page.topRated.map((p) => p.id)).toEqual(['7', '4', '6']);
    expect(page.others.map((p) => p.id)).toEqual(['5']);
  });

  it('puts every product in top rated when the category is small', async () => {
    const { service } = build();
    const page = await service.categoryPage('mens-clothing');
    expect(page.topRated.map((p) => p.id)).toEqual(['2', '1']);
    expect(page.others).toEqual([]);
  });

  it('rejects an unknown category', async () => {
    const { service } = build();
    await expect(service.categoryPage('garden')).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });
});

describe('search', () => {
  it('matches title, description and category, case-insensitively', async () => {
    const { service } = build();
    expect((await service.search('DRIVE')).map((p) => p.id)).toEqual(['4', '6']);
    expect((await service.search('jewelery')).map((p) => p.id)).toEqual(['3']);
  });

  it('requires every term to match', async () => {
    const { service } = build();
    expect((await service.search('solid gold')).map((p) => p.id)).toEqual(['3']);
  });

  it('returns nothing when no product matches', async () => {
    const { service } = build();
    expect(await service.search('banana')).toEqual([]);
  });
});

describe('product', () => {
  it('returns the product or a NOT_FOUND error', async () => {
    const { service } = build();
    expect((await service.product('3')).title).toBe('Gold Ring');
    await expect(service.product('nope')).rejects.toMatchObject({ code: 'NOT_FOUND' });
  });
});
