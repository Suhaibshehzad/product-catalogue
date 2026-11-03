import { describe, expect, it } from 'vitest';
import { loadConfig } from '../src/config.js';

const base = {
  FEATURED_PRODUCT_IDS: '3, 5,11,,12',
  SALES_INBOX: 'sales@example.com',
  MAIL_FROM: 'shop@example.com',
  SMTP_HOST: 'localhost',
  SMTP_PORT: '1025',
};

describe('loadConfig', () => {
  it('parses lists, numbers and booleans with defaults', () => {
    const config = loadConfig(base);
    expect(config.FEATURED_PRODUCT_IDS).toEqual(['3', '5', '11', '12']);
    expect(config.SMTP_PORT).toBe(1025);
    expect(config.SMTP_SECURE).toBe(false);
    expect(config.PORT).toBe(3000);
  });

  it('fails fast listing every invalid variable', () => {
    expect(() => loadConfig({ ...base, SALES_INBOX: 'nope', FEATURED_PRODUCT_IDS: ' , ' })).toThrow(
      /SALES_INBOX[\s\S]*FEATURED_PRODUCT_IDS|FEATURED_PRODUCT_IDS[\s\S]*SALES_INBOX/,
    );
  });
});
