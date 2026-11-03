import rateLimit from '@fastify/rate-limit';
import Fastify, { type FastifyServerOptions } from 'fastify';
import type { CatalogueService } from '../services/catalogue-service.js';
import type { EnquiryService } from '../services/enquiry-service.js';
import { registerErrorHandling } from './errors.js';
import { catalogueRoutes } from './routes/catalogue.js';
import { enquiryRoutes, type EnquiryRouteOptions } from './routes/enquiries.js';

export interface AppDependencies {
  catalogue: CatalogueService;
  enquiries: EnquiryService;
  enquiryRateLimit?: EnquiryRouteOptions['rateLimit'];
  logger?: FastifyServerOptions['logger'];
}

export async function buildApp(deps: AppDependencies) {
  const app = Fastify({ logger: deps.logger ?? false, bodyLimit: 16 * 1024 });

  registerErrorHandling(app);
  await app.register(rateLimit, { global: false });

  app.get('/health', async () => ({ status: 'ok' }));
  await app.register(catalogueRoutes(deps.catalogue), { prefix: '/api' });
  await app.register(
    enquiryRoutes(deps.enquiries, {
      rateLimit: deps.enquiryRateLimit ?? { max: 5, timeWindow: '1 minute' },
    }),
    { prefix: '/api' },
  );

  return app;
}
