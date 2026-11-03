import 'dotenv/config';
import { FakeStoreProductSource } from './adapters/fakestore-product-source.js';
import { SmtpEnquiryNotifier } from './adapters/smtp-enquiry-notifier.js';
import { loadConfig } from './config.js';
import { buildApp } from './http/app.js';
import { CatalogueService } from './services/catalogue-service.js';
import { EnquiryService } from './services/enquiry-service.js';

// Composition root: the only place that knows which adapters are in use.
const config = loadConfig();

const productSource = new FakeStoreProductSource({
  baseUrl: config.FAKESTORE_BASE_URL,
  cacheTtlMs: config.PRODUCT_CACHE_TTL_SECONDS * 1000,
});
const notifier = new SmtpEnquiryNotifier({
  host: config.SMTP_HOST,
  port: config.SMTP_PORT,
  secure: config.SMTP_SECURE,
  user: config.SMTP_USER || undefined,
  pass: config.SMTP_PASS || undefined,
  from: config.MAIL_FROM,
  to: config.SALES_INBOX,
});

const catalogue = new CatalogueService(
  productSource,
  { featuredProductIds: config.FEATURED_PRODUCT_IDS, categoryTopRatedCount: 3 },
  (id) => app.log.warn({ productId: id }, 'Featured product not found in data source'),
);
const enquiries = new EnquiryService(catalogue, notifier);

const app = await buildApp({ catalogue, enquiries, logger: true });

try {
  await app.listen({ port: config.PORT, host: config.HOST });
} catch (err) {
  app.log.error(err);
  process.exit(1);
}

for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.once(signal, () => void app.close().then(() => process.exit(0)));
}
