import type { FastifyError, FastifyInstance } from 'fastify';
import { ZodError } from 'zod';
import { AppError } from '../domain/errors.js';

const statusByCode: Record<AppError['code'], number> = {
  NOT_FOUND: 404,
  VALIDATION_FAILED: 400,
  UPSTREAM_UNAVAILABLE: 502,
  DELIVERY_FAILED: 502,
};

/** Every error leaves the API as `{ error: { code, message, details? } }`. */
export function registerErrorHandling(app: FastifyInstance): void {
  app.setErrorHandler((err: FastifyError | Error, request, reply) => {
    if (err instanceof ZodError) {
      return reply.status(400).send({
        error: {
          code: 'VALIDATION_FAILED',
          message: 'Request is invalid',
          details: err.issues.map((i) => ({ field: i.path.join('.'), message: i.message })),
        },
      });
    }
    if (err instanceof AppError) {
      const status = statusByCode[err.code];
      if (status >= 500) request.log.error({ err: err.cause ?? err }, err.message);
      return reply.status(status).send({ error: { code: err.code, message: err.message } });
    }

    const status = 'statusCode' in err && err.statusCode ? err.statusCode : 500;
    if (status === 429) {
      return reply
        .status(429)
        .send({ error: { code: 'RATE_LIMITED', message: 'Too many requests, try again later' } });
    }
    if (status < 500) {
      // Fastify's own client errors, e.g. malformed JSON or body too large.
      return reply.status(status).send({ error: { code: 'BAD_REQUEST', message: err.message } });
    }
    request.log.error({ err }, 'Unhandled error');
    return reply
      .status(500)
      .send({ error: { code: 'INTERNAL_ERROR', message: 'Something went wrong' } });
  });

  app.setNotFoundHandler((_request, reply) =>
    reply.status(404).send({ error: { code: 'NOT_FOUND', message: 'Route not found' } }),
  );
}
