import { describe, expect, it, vi } from 'vitest';
import type { Transporter } from 'nodemailer';
import { SmtpEnquiryNotifier } from '../src/adapters/smtp-enquiry-notifier.js';
import { product } from './fakes.js';

describe('SmtpEnquiryNotifier', () => {
  it('sends a plain-text email to the sales inbox with reply-to set to the customer', async () => {
    const sendMail = vi.fn(async (_mail: Record<string, unknown>) => ({}));
    const notifier = new SmtpEnquiryNotifier(
      { host: 'h', port: 1, secure: false, from: 'shop@example.com', to: 'sales@example.com' },
      { sendMail } as unknown as Transporter,
    );

    await notifier.notify({
      product: product({ id: '3', title: 'Gold Ring', price: { amount: 9.5, currency: 'USD' } }),
      customer: { name: 'Ada', email: 'ada@example.com', message: '<b>hi</b>' },
      receivedAt: new Date('2026-11-02T10:00:00Z'),
    });

    const mail = sendMail.mock.calls[0]![0];
    expect(mail).toMatchObject({
      from: 'shop@example.com',
      to: 'sales@example.com',
      replyTo: { name: 'Ada', address: 'ada@example.com' },
      subject: 'New enquiry: Gold Ring',
    });
    expect(mail).not.toHaveProperty('html');
    expect(mail.text).toContain('Gold Ring (ID 3)');
    expect(mail.text).toContain('9.50 USD');
    expect(mail.text).toContain('Phone:    —');
    expect(mail.text).toContain('<b>hi</b>');
  });
});
