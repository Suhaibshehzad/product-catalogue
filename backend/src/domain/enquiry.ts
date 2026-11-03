import type { Product } from './product.js';

export interface CustomerContact {
  name: string;
  email: string;
  phone?: string;
  message?: string;
}

export interface Enquiry {
  product: Product;
  customer: CustomerContact;
  receivedAt: Date;
}
