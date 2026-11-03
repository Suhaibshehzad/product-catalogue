/** Domain errors carry a stable code; the HTTP layer maps them to status codes. */
export class AppError extends Error {
  constructor(
    readonly code: 'NOT_FOUND' | 'VALIDATION_FAILED' | 'UPSTREAM_UNAVAILABLE' | 'DELIVERY_FAILED',
    message: string,
    options?: { cause?: unknown },
  ) {
    super(message, options);
    this.name = 'AppError';
  }
}

export const notFound = (what: string) => new AppError('NOT_FOUND', `${what} not found`);
