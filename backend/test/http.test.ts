import { afterEach, describe, expect, it } from 'vitest';
import { buildApp } from '../src/http/app.js';
import { CatalogueService } from '../src/services/catalogue-service.js';
import { EnquiryService } from '../src/services/enquiry-service.js';
import { catalogueFixture, InMemoryProductSource, RecordingNotifier } from './fakes.js';

let app: Awaited<ReturnType<typeof buildApp>>;

const setup = async (opts: { rateLimitMax?: number } = {}) => {
  const source = new InMemoryProductSource(catalogueFixture());
  const notifier = new RecordingNotifier();
  const catalogue = new CatalogueService(source, {
    featuredProductIds: ['4', '2', '3', '7', '1'],
    categoryTopRatedCount: 3,
  });
  app = await buildApp({
    catalogue,
    enquiries: new EnquiryService(catalogue, notifier),
    enquiryRateLimit: { max: opts.rateLimitMax ?? 100, timeWindow: '1 minute' },
  });
  return { notifier };
};

afterEach(() => app?.close());

const validEnquiry = {
  productId: '3',
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  phone: '+44 20 7946 0000',
  message: 'Is this available in size M?',
};

describe('catalogue routes', () => {
  it('GET /api/products/featured returns the 5 chosen products', async () => {
    await setup();
    const res = await app.inject('/api/products/featured');
    expect(res.statusCode).toBe(200);
    expect(res.json().products.map((p: { id: string }) => p.id)).toEqual(['4', '2', '3', '7', '1']);
  });

  it('GET /api/categories lists categories with slugs', async () => {
    await setup();
    const res = await app.inject('/api/categories');
    expect(res.json().categories).toContainEqual({ slug: 'mens-clothing', name: "men's clothing" });
  });

  it('GET /api/categories/:slug returns top rated and other products', async () => {
    await setup();
    const body = (await app.inject('/api/categories/electronics')).json();
    expect(body.topRated).toHaveLength(3);
    expect(body.others).toHaveLength(1);
  });

  it('GET /api/categories/:slug returns 404 for an unknown category', async () => {
    await setup();
    const res = await app.inject('/api/categories/garden');
    expect(res.statusCode).toBe(404);
    expect(res.json()).toEqual({ error: { code: 'NOT_FOUND', message: 'Category not found' } });
  });

  it('GET /api/products?q= returns only matching products', async () => {
    await setup();
    const res = await app.inject('/api/products?q=drive');
    expect(res.json().products.map((p: { id: string }) => p.id)).toEqual(['4', '6']);
  });

  it('GET /api/products without q lists all products', async () => {
    await setup();
    const res = await app.inject('/api/products');
    expect(res.json().products).toHaveLength(7);
  });

  it('GET /api/products rejects an overly long search term', async () => {
    await setup();
    const res = await app.inject(`/api/products?q=${'a'.repeat(101)}`);
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('VALIDATION_FAILED');
  });

  it('GET /api/products/:id returns product details or 404', async () => {
    await setup();
    expect((await app.inject('/api/products/3')).json().product.title).toBe('Gold Ring');
    expect((await app.inject('/api/products/999')).statusCode).toBe(404);
  });
});

describe('POST /api/enquiries', () => {
  const post = (payload: unknown) => app.inject({ method: 'POST', url: '/api/enquiries', payload: payload as object });

  it('emails the sales inbox and returns 202', async () => {
    const { notifier } = await setup();
    const res = await post(validEnquiry);

    expect(res.statusCode).toBe(202);
    expect(res.json()).toEqual({ status: 'sent' });
    expect(notifier.sent[0]?.customer).toEqual({
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      phone: '+44 20 7946 0000',
      message: 'Is this available in size M?',
    });
  });

  it('treats blank optional fields as absent', async () => {
    const { notifier } = await setup();
    await post({ ...validEnquiry, phone: '  ', message: '' });
    expect(notifier.sent[0]?.customer).toEqual({ name: 'Ada Lovelace', email: 'ada@example.com' });
  });

  it.each([
    ['missing name', { ...validEnquiry, name: '' }, 'name'],
    ['invalid email', { ...validEnquiry, email: 'not-an-email' }, 'email'],
    ['invalid phone', { ...validEnquiry, phone: 'call me' }, 'phone'],
    ['header injection in name', { ...validEnquiry, name: 'Ada\r\nBcc: x@evil.test' }, 'name'],
    ['message too long', { ...validEnquiry, message: 'x'.repeat(2001) }, 'message'],
  ])('returns 400 for %s without sending', async (_label, payload, field) => {
    const { notifier } = await setup();
    const res = await post(payload);

    expect(res.statusCode).toBe(400);
    expect(res.json().error.details.map((d: { field: string }) => d.field)).toContain(field);
    expect(notifier.sent).toEqual([]);
  });

  it('returns 404 for an unknown product', async () => {
    await setup();
    expect((await post({ ...validEnquiry, productId: '999' })).statusCode).toBe(404);
  });

  it('returns 502 when the email cannot be delivered, so the client never shows "Thank you"', async () => {
    const { notifier } = await setup();
    notifier.failWith = new Error('SMTP down');
    const res = await post(validEnquiry);
    expect(res.statusCode).toBe(502);
    expect(res.json().error.code).toBe('DELIVERY_FAILED');
  });

  it('rate limits repeated submissions', async () => {
    await setup({ rateLimitMax: 2 });
    await post(validEnquiry);
    await post(validEnquiry);
    const res = await post(validEnquiry);
    expect(res.statusCode).toBe(429);
    expect(res.json().error.code).toBe('RATE_LIMITED');
  });

  it('rejects malformed JSON with a 400', async () => {
    await setup();
    const res = await app.inject({
      method: 'POST',
      url: '/api/enquiries',
      headers: { 'content-type': 'application/json' },
      payload: '{not json',
    });
    expect(res.statusCode).toBe(400);
  });
});
