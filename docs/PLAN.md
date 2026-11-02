# Plan — Product Catalogue PoC

Source brief: "Code Challenge: AI-Native Engineer". Time-box 2–3h.

## Goal

An interactive proof of concept of a product catalogue that is a **foundation, not a throwaway**.
The product data source, look and feel, and email provider are all expected to change, so each
sits behind a boundary that can be swapped without touching the rest.

## Stack

| Layer   | Choice                              | Why |
|---------|-------------------------------------|-----|
| Client  | iOS, Swift + SwiftUI (iOS 17+)      | Native strength of the author; `@Observable` + async/await keep view models small and testable. |
| Backend | Node.js + TypeScript + Fastify      | Schema validation built in, `inject()` makes HTTP tests fast without a live server. |
| Email   | SMTP via nodemailer → Mailpit (dev) | Free, local, no account; reviewer can see the "sales inbox" at `localhost:8025`. |
| Data    | Fake Store API, **backend only**    | Client never calls it (constraint #2). |

## Architecture

```
iOS app ──HTTP/JSON──▶ backend (/api)
                         routes ─▶ services ─▶ ports
                                               ├─ ProductSource   ◀─ FakeStoreProductSource (cached)
                                               └─ EnquiryNotifier ◀─ SmtpEnquiryNotifier
```

- **Backend owns the product contract.** It maps Fake Store data into its own `Product` DTO, so the
  client is unaffected when the data source changes.
- **Ports & adapters.** `ProductSource` and `EnquiryNotifier` are interfaces; adapters are chosen
  in one composition root from config. Tests use in-memory fakes.
- **iOS `Core` local Swift package** holds models, `APIClient`, `CatalogueRepository` protocol and
  view models — testable with `swift test`, no simulator. The app target is a thin SwiftUI shell, so
  restyling (incoming creative work) does not touch logic.

## API

| Method | Path                        | Purpose |
|--------|-----------------------------|---------|
| GET    | `/api/products/featured`    | Owner-chosen 5 "top rated" products (home page) |
| GET    | `/api/categories`           | Category list |
| GET    | `/api/categories/:slug`     | `{ topRated: Product[], others: Product[] }` |
| GET    | `/api/products?q=term`      | Search (case-insensitive text match) |
| GET    | `/api/products/:id`         | Product detail |
| POST   | `/api/enquiries`            | Validate, email sales inbox, `202` on success |
| GET    | `/health`                   | Liveness |

Errors use one shape: `{ error: { code, message } }`.

## Acceptance criteria → assumptions

1. **Home — "I have chosen 5 top rated":** curated by the owner, not computed. Stored as a list of
   product IDs in config (`FEATURED_PRODUCT_IDS`) until a CMS/admin exists.
2. **Category — "top rated for that category":** top 3 by Fake Store `rating.rate`, then the rest.
   Category "slug" is the URL-encoded Fake Store category name.
3. **Search:** Fake Store has no search endpoint, so the backend filters on title, description and
   category (case-insensitive substring). Triggered on button press, per the criterion. Empty term
   is rejected client-side.
4. **Product page:** tapping any product tile navigates to detail.
5. **Enquiry:** fields = name (required), email (required, validated), phone (optional),
   message (optional, max length). Server validates; recipient is `SALES_INBOX` from env. The
   "Thank you" screen is shown **only after** the backend confirms the email was sent; failures show
   a retryable error.

## Deliberately out of scope

Auth, basket/checkout, pagination (20 products), persistence/DB, design system/branding (creative
work in progress), AWS infrastructure (described, not built), Android/web clients.

## Security basics

No secrets committed (`.env.example` only); input validation on every route; rate limit on
`POST /api/enquiries`; email body content escaped; ATS exception limited to local networking.

## Testing strategy

- **Backend (Vitest):** service tests with fake ports (featured selection, category split, search
  matching, enquiry validation/notifier failure); route tests via `fastify.inject()`; adapter
  mapping test for Fake Store → `Product`.
- **iOS (Swift Testing):** view-model tests with a mock repository (loading/success/error states,
  enquiry form validation and thank-you transition); `APIClient` decoding tests with fixture JSON.
- **iOS UI (XCUITest):** one smoke test of the enquiry happy path, if time allows.

## Steps

1. Scaffold repo, `docs/PLAN.md`, `CLAUDE.md`, `.gitignore`, initial commit on `main`.
2. Branch `feature/catalogue-mvp`.
3. Backend: ports, Fake Store adapter, services, routes, SMTP notifier, tests.
4. iOS: `Core` package (models, API client, view models, tests), then SwiftUI screens.
5. Manual end-to-end run: backend + Mailpit + simulator.
6. Docs: `README.md`, `DECISIONS.md`, `AI_USAGE.md`, time spent.
7. Review pass, push, open PR into `main`.
