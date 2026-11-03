import type { CustomerContact } from '../domain/enquiry.js';
import { AppError } from '../domain/errors.js';
import type { EnquiryNotifier } from '../ports/enquiry-notifier.js';
import type { CatalogueService } from './catalogue-service.js';

export class EnquiryService {
  constructor(
    private readonly catalogue: CatalogueService,
    private readonly notifier: EnquiryNotifier,
    private readonly now: () => Date = () => new Date(),
  ) {}

  /** Resolves only once the sales inbox has accepted the email. */
  async submit(productId: string, customer: CustomerContact): Promise<void> {
    const product = await this.catalogue.product(productId);
    try {
      await this.notifier.notify({ product, customer, receivedAt: this.now() });
    } catch (cause) {
      throw new AppError('DELIVERY_FAILED', 'Your enquiry could not be sent. Please try again.', {
        cause,
      });
    }
  }
}
