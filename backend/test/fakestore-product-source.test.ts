import { describe, expect, it, vi } from 'vitest';
import { FakeStoreProductSource } from '../src/adapters/fakestore-product-source.js';

const upstream = [
  { id: 1, title: 'Backpack', price: 109.95, description: 'Bag', category: "men's clothing", image: 'https://x/1.png', rating: { rate: 3.9, count: 120 } },
  { id: 9, title: 'WD Drive', price: 64, description: 'Storage', category: 'electronics', image: 'https://x/9.png', rating: { rate: 3.3, count: 203 } },
];

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

const build = (fetchFn: typeof fetch, now = () => 0) =>
  new FakeStoreProductSource({ baseUrl: 'https://fakestore.test', cacheTtlMs: 1000, fetchFn, now });

describe('FakeStoreProductSource', () => {
  it('maps Fake Store products to our Product contract', async () => {
    const source = build(vi.fn(async () => jsonResponse(upstream)));
    expect(await source.getProduct('1')).toEqual({
      id: '1',
      title: 'Backpack',
      description: 'Bag',
      price: { amount: 109.95, currency: 'USD' },
      imageUrl: 'https://x/1.png',
      category: { slug: 'mens-clothing', name: "men's clothing" },
      rating: { average: 3.9, count: 120 },
    });
  });

  it('derives sorted categories and filters by category and text', async () => {
    const source = build(vi.fn(async () => jsonResponse(upstream)));
    expect((await source.listCategories()).map((c) => c.slug)).toEqual(['electronics', 'mens-clothing']);
    expect((await source.listProducts({ categorySlug: 'electronics' })).map((p) => p.id)).toEqual(['9']);
    expect((await source.listProducts({ text: 'bag' })).map((p) => p.id)).toEqual(['1']);
  });

  it('caches until the TTL expires and shares concurrent requests', async () => {
    let time = 0;
    const fetchFn = vi.fn(async () => jsonResponse(upstream));
    const source = build(fetchFn, () => time);

    await Promise.all([source.listProducts(), source.listProducts()]);
    await source.getProduct('1');
    expect(fetchFn).toHaveBeenCalledTimes(1);

    time = 1001;
    await source.listProducts();
    expect(fetchFn).toHaveBeenCalledTimes(2);
  });

  it('raises UPSTREAM_UNAVAILABLE on HTTP errors, network errors and bad payloads', async () => {
    await expect(build(vi.fn(async () => jsonResponse({}, 503))).listProducts()).rejects.toMatchObject({
      code: 'UPSTREAM_UNAVAILABLE',
    });
    await expect(
      build(vi.fn(async () => Promise.reject(new TypeError('fetch failed')))).listProducts(),
    ).rejects.toMatchObject({ code: 'UPSTREAM_UNAVAILABLE' });
    await expect(build(vi.fn(async () => jsonResponse([{ id: 'oops' }]))).listProducts()).rejects.toMatchObject({
      code: 'UPSTREAM_UNAVAILABLE',
    });
  });

  it('does not cache failures', async () => {
    const fetchFn = vi
      .fn<typeof fetch>()
      .mockRejectedValueOnce(new TypeError('fetch failed'))
      .mockResolvedValueOnce(jsonResponse(upstream));
    const source = build(fetchFn);

    await expect(source.listProducts()).rejects.toThrow();
    expect(await source.listProducts()).toHaveLength(2);
  });
});
