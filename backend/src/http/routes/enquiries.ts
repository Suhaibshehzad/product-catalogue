import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import type { EnquiryService } from '../../services/enquiry-service.js';

// Rejects control characters so names can't inject email headers or forge lines.
const singleLine = /^[^\p{Cc}]*$/u;
const emptyToUndefined = (v: unknown) => (typeof v === 'string' && v.trim() === '' ? undefined : v);

export const enquiryBody = z.object({
  productId: z.string().regex(/^[A-Za-z0-9_-]{1,64}$/),
  name: z.string().trim().min(1, 'Name is required').max(100).regex(singleLine, 'Invalid name'),
  email: z.string().trim().max(254).email('Enter a valid email address'),
  phone: z.preprocess(
    emptyToUndefined,
    z
      .string()
      .trim()
      .regex(/^\+?[0-9 ()-]{6,20}$/, 'Enter a valid phone number')
      .optional(),
  ),
  message: z.preprocess(emptyToUndefined, z.string().trim().max(2000).optional()),
});

export interface EnquiryRouteOptions {
  rateLimit: { max: number; timeWindow: string | number };
}

export const enquiryRoutes =
  (enquiries: EnquiryService, options: EnquiryRouteOptions): FastifyPluginAsync =>
  async (app) => {
    app.post('/enquiries', { config: { rateLimit: options.rateLimit } }, async (request, reply) => {
      const { productId, ...customer } = enquiryBody.parse(request.body);
      await enquiries.submit(productId, customer);
      return reply.status(202).send({ status: 'sent' });
    });
  };
