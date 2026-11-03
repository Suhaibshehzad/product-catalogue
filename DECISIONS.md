# Decisions

Assumptions, cuts and judgement calls. The fuller rationale for the product assumptions is in
[`docs/PLAN.md`](docs/PLAN.md#acceptance-criteria--assumptions).

## Product assumptions

| # | Decision | Why |
|---|----------|-----|
| 1 | Home page "5 top rated" is an owner-curated list of IDs in `FEATURED_PRODUCT_IDS`. | The brief says "I have chosen", so the list is curated, not computed. Config works until an admin/CMS exists. |
| 2 | Category "top rated" is the top 3 by Fake Store rating, then the rest. | No per-category curation exists; 3 keeps the split visible with ~5 products per category. |
| 3 | Category slugs are derived from names (`men's clothing` → `mens-clothing`). | Fake Store has no category IDs; slugs give stable, URL-safe keys. |
| 4 | Search is done in the backend: case-insensitive, every word must match title, description or category. It runs on button press, and empty terms are rejected in the client. | Fake Store has no search endpoint; with 20 products, in-memory filtering is enough. |
| 5 | The thank-you screen appears only after the backend confirms the email was accepted (`202`). Failures show a retryable error. | The criterion is that sales actually receives the enquiry. |
| 6 | Enquiry fields: name and email required, phone and message optional (message length-capped). | The minimum needed for sales to reply. |
| 7 | Email is plain text with reply-to set to the customer. | Avoids HTML injection from customer input; sales can reply directly. |

## Architecture

- **Backend owns the `Product` DTO.** Fake Store field names stop at the adapter, so swapping the
  data source means writing a new `ProductSource` adapter.
- **Ports & adapters with one composition root** (`src/server.ts`), so the email provider (e.g. SES)
  can be replaced the same way.
- **Products are cached in memory** (`PRODUCT_CACHE_TTL_SECONDS`, default 5 min). This is fine for a
  single instance; several instances would need a shared cache.
- **iOS logic lives in the `Core` Swift package**, so it is testable with `swift test` and the
  upcoming visual redesign only touches the thin SwiftUI layer.

## How the design grows beyond the PoC

Each change the brief anticipates has a single place to land:

| Expected change | Where it lands | What stays untouched |
|-----------------|----------------|----------------------|
| Product data source (real catalogue, CMS, DB) | A new `ProductSource` adapter, wired in `server.ts` | Services, routes, API contract, iOS app |
| Email provider (SES, SendGrid) | A new `EnquiryNotifier` adapter | Enquiry validation, service, app flow |
| Look and feel (creative work in progress) | SwiftUI views in `ios/App` | `CatalogueCore` view models, networking, tests |
| More clients (web, Android) | Call the same `/api` contract | Backend and data source |
| Curated "top rated" moving to an admin tool | Replace the `FEATURED_PRODUCT_IDS` config read | Home page logic and contract |

Tests target the seams: services are tested with fake ports, routes through `inject()`, and view
models with a mock repository. Swapping an adapter therefore doesn't invalidate the suite.

## Next, with another day

1. **Contract as code:** generate an OpenAPI spec from the zod schemas and check the iOS models
   against it in CI, so client and backend can't drift.
2. **CI:** GitHub Actions running typecheck, backend tests, `swift test` and the smoke script on
   every PR.
3. **Enquiry reliability:** queue enquiries (e.g. SQS) with retry, so a mail outage doesn't lose a
   lead. Today a failure is shown to the customer and they retry.
4. **Deploy to AWS:** the backend in a container on App Runner or ECS, SES for email, config from
   SSM Parameter Store. The code needs no changes, only adapters and config.
5. **Product polish:** images cached on the client, accessibility pass (Dynamic Type,
   VoiceOver labels), and pagination once the catalogue outgrows 20 products.

## Cuts (out of scope)

Auth, basket/checkout, pagination, a database, design system/branding, AWS infrastructure,
Android/web clients. See [`docs/PLAN.md`](docs/PLAN.md#deliberately-out-of-scope).

## Security

- No secrets committed; `.env.example` holds safe placeholders and `.env` is git-ignored.
- Every route validates input; request bodies are capped at 16 KB.
- `POST /api/enquiries` is rate-limited to 5 requests per minute per IP. Rejected (400) requests
  count toward the limit too, which makes form spam harder.
- iOS App Transport Security allows plain HTTP only to local addresses.
- The backend binds to `127.0.0.1` by default, so in dev it is not reachable from the local
  network or VPN. The simulator shares the Mac's loopback interface, so it still works. To test on a
  physical device, set `HOST=0.0.0.0` and point `API_BASE_URL` at the Mac's LAN address.

## Build & verification notes

- **Dependencies are pinned to versions at least a week old.** They were installed through the
  company Artifactory mirror, which refuses package versions younger than 7 days, using
  `npm install --before=2026-10-25`. As a result, e.g. `fastify` is 5.12.7 rather than the
  then-latest 5.12.8.
- **The lockfile references `registry.npmjs.org`.** The install wrote Artifactory URLs into
  `package-lock.json`; they were rewritten to the public registry so the lockfile works outside the
  company network. The integrity hashes are unchanged, because the mirror serves the same tarballs.
- **Fixed in the smoke script (`scripts/e2e-smoke.sh`):** JSON bodies are built in variables. Under
  macOS's default bash 3.2, the inline `"$(… -d "{\"…\"}")"` form was brace-expanded into several
  malformed requests, and `check` only compared its first two values, so it reported a pass. `check`
  now fails if it gets the wrong number of arguments.
- **Fixed in the SMTP test:** the `sendMail` mock now declares its parameter, so the test
  type-checks (the tests already passed at runtime).
