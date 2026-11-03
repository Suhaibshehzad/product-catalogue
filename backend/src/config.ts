import { z } from 'zod';

const idList = z
  .string()
  .transform((s) => s.split(',').map((id) => id.trim()).filter(Boolean))
  .pipe(z.array(z.string()).min(1, 'At least one featured product ID is required'));

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(3000),
  // Loopback only by default; set 0.0.0.0 to serve a physical device on the LAN.
  HOST: z.string().default('127.0.0.1'),
  FAKESTORE_BASE_URL: z.string().url().default('https://fakestoreapi.com'),
  PRODUCT_CACHE_TTL_SECONDS: z.coerce.number().int().nonnegative().default(300),
  FEATURED_PRODUCT_IDS: idList,
  SALES_INBOX: z.string().email(),
  MAIL_FROM: z.string().min(1),
  SMTP_HOST: z.string().min(1),
  SMTP_PORT: z.coerce.number().int().positive(),
  SMTP_SECURE: z.enum(['true', 'false']).default('false').transform((v) => v === 'true'),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
});

export type Config = z.infer<typeof envSchema>;

/** Fails fast at startup with every misconfigured variable listed. */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const result = envSchema.safeParse(env);
  if (!result.success) {
    const problems = result.error.issues.map((i) => `  ${i.path.join('.')}: ${i.message}`);
    throw new Error(`Invalid configuration (see .env.example):\n${problems.join('\n')}`);
  }
  return result.data;
}
