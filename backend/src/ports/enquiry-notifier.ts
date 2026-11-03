import type { Enquiry } from '../domain/enquiry.js';

/** Delivers an enquiry to the sales team. Throws if delivery fails. */
export interface EnquiryNotifier {
  notify(enquiry: Enquiry): Promise<void>;
}
