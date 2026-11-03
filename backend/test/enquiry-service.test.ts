import { describe, expect, it } from 'vitest';
import { CatalogueService } from '../src/services/catalogue-service.js';
import { EnquiryService } from '../src/services/enquiry-service.js';
import { catalogueFixture, InMemoryProductSource, RecordingNotifier } from './fakes.js';

const fixedNow = new Date('2026-11-02T10:00:00Z');
const customer = { name: 'Ada Lovelace', email: 'ada@example.com' };

const build = () => {
  const notifier = new RecordingNotifier();
  const catalogue = new CatalogueService(new InMemoryProductSource(catalogueFixture()), {
    featuredProductIds: [],
    categoryTopRatedCount: 3,
  });
  return { notifier, service: new EnquiryService(catalogue, notifier, () => fixedNow) };
};

describe('EnquiryService', () => {
  it('sends the enquiry with the full product details', async () => {
    const { service, notifier } = build();
    await service.submit('3', customer);

    expect(notifier.sent).toHaveLength(1);
    expect(notifier.sent[0]).toMatchObject({
      product: { id: '3', title: 'Gold Ring' },
      customer,
      receivedAt: fixedNow,
    });
  });

  it('rejects an enquiry for an unknown product without sending', async () => {
    const { service, notifier } = build();
    await expect(service.submit('999', customer)).rejects.toMatchObject({ code: 'NOT_FOUND' });
    expect(notifier.sent).toEqual([]);
  });

  it('reports DELIVERY_FAILED when the email cannot be sent', async () => {
    const { service, notifier } = build();
    notifier.failWith = new Error('SMTP down');
    await expect(service.submit('3', customer)).rejects.toMatchObject({ code: 'DELIVERY_FAILED' });
  });
});
