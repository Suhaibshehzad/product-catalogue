import nodemailer, { type Transporter } from 'nodemailer';
import type { Enquiry } from '../domain/enquiry.js';
import type { EnquiryNotifier } from '../ports/enquiry-notifier.js';

export interface SmtpOptions {
  host: string;
  port: number;
  secure: boolean;
  user?: string;
  pass?: string;
  from: string;
  to: string;
}

/**
 * Sends enquiries as plain-text email. Plain text avoids HTML injection from
 * customer-supplied fields; swapping provider (SES, SendGrid) means a new adapter.
 */
export class SmtpEnquiryNotifier implements EnquiryNotifier {
  private readonly transporter: Transporter;

  constructor(
    private readonly options: SmtpOptions,
    transporter?: Transporter,
  ) {
    this.transporter =
      transporter ??
      nodemailer.createTransport({
        host: options.host,
        port: options.port,
        secure: options.secure,
        auth: options.user ? { user: options.user, pass: options.pass } : undefined,
      });
  }

  async notify(enquiry: Enquiry): Promise<void> {
    await this.transporter.sendMail({
      from: this.options.from,
      to: this.options.to,
      replyTo: { name: enquiry.customer.name, address: enquiry.customer.email },
      subject: `New enquiry: ${enquiry.product.title}`,
      text: formatEnquiryEmail(enquiry),
    });
  }
}

export function formatEnquiryEmail({ product, customer, receivedAt }: Enquiry): string {
  return [
    'A customer has enquired about a product.',
    '',
    `Product:  ${product.title} (ID ${product.id})`,
    `Price:    ${product.price.amount.toFixed(2)} ${product.price.currency}`,
    '',
    `Name:     ${customer.name}`,
    `Email:    ${customer.email}`,
    `Phone:    ${customer.phone ?? '—'}`,
    '',
    'Message:',
    customer.message ?? '—',
    '',
    `Received: ${receivedAt.toISOString()}`,
  ].join('\n');
}
