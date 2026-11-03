# Product Catalogue PoC

An iOS (SwiftUI) client and a Node/TypeScript (Fastify) backend for browsing a product catalogue
and sending product enquiries to a sales inbox. The plan, assumptions and scope are in
[`docs/PLAN.md`](docs/PLAN.md); cuts and judgement calls are in [`DECISIONS.md`](DECISIONS.md).

```
iOS app ──HTTP/JSON──▶ backend (/api)
                         routes ─▶ services ─▶ ports
                                               ├─ ProductSource   ◀─ FakeStoreProductSource (cached)
                                               └─ EnquiryNotifier ◀─ SmtpEnquiryNotifier
```

The app talks only to the backend. The backend owns the `Product` contract and is the only
component that calls the Fake Store API, so the data source, email provider and visual design can
each change without touching the others.

## Stack choice

| Layer   | Choice | Why |
|---------|--------|-----|
| Client  | iOS app, Swift 6 + SwiftUI (iOS 17+) | My strongest platform, so review time goes on design rather than syntax. `@Observable` + async/await keep the view models small and testable without a simulator. |
| Backend | Node.js + TypeScript (Fastify) | TypeScript strict mode catches contract drift early; Fastify's `inject()` gives fast HTTP tests without a live server; zod validates both requests and the upstream Fake Store data. |
| Email   | SMTP via nodemailer → Mailpit | Free, local and account-free, as the brief requires. Production can switch to SES or another provider by changing config or adding one adapter. |

## Requirements

- Node.js 22+
- [Mailpit](https://mailpit.axllent.org/) for a local sales inbox (`brew install mailpit`)
- Xcode 26 with an iOS 17+ simulator (for the app)

## Run it

```sh
# 1. Local sales inbox — open http://localhost:8025
mailpit

# 2. Backend on http://localhost:3000
cd backend
npm ci
cp .env.example .env
npm run dev

# 3. App
open ios/Catalogue.xcodeproj   # run the "Catalogue" scheme on a simulator
```

The app reads its backend URL from the `API_BASE_URL` build setting (default
`http://localhost:3000`). App Transport Security allows plain HTTP to local addresses only.

## Configuration

All backend settings are environment variables, documented in
[`backend/.env.example`](backend/.env.example). The backend validates them at startup and lists
every invalid one. Key settings:

| Variable               | Purpose |
|------------------------|---------|
| `FEATURED_PRODUCT_IDS` | Owner-chosen "top rated" products on the home page, in display order |
| `SALES_INBOX`          | Where enquiries are emailed |
| `SMTP_*`, `MAIL_FROM`  | Mail transport; defaults point at Mailpit |
| `FAKESTORE_BASE_URL`, `PRODUCT_CACHE_TTL_SECONDS` | Product data source and cache lifetime |

## API

| Method | Path                     | Purpose |
|--------|--------------------------|---------|
| GET    | `/api/products/featured` | The five featured products |
| GET    | `/api/categories`        | Category list |
| GET    | `/api/categories/:slug`  | `{ topRated, others }` for one category |
| GET    | `/api/products?q=term`   | Search |
| GET    | `/api/products/:id`      | Product detail |
| POST   | `/api/enquiries`         | Validate and email the sales inbox; `202` once sent (rate-limited to 5/min) |
| GET    | `/health`                | Liveness |

Errors always have the shape `{ "error": { "code", "message" } }`.

## Tests

| Suite | Command | Covers |
|-------|---------|--------|
| Backend unit + route tests | `cd backend && npm test` | Services with fake ports, routes via `inject()`, adapter mapping |
| Backend type check | `cd backend && npm run typecheck` | |
| iOS Core | `cd ios/Core && swift test` | View models, API client decoding and errors |
| iOS UI (stub data) | Xcode → `CatalogueUITests/EnquiryFlowUITests` | Enquiry happy path |
| End-to-end smoke | `scripts/e2e-smoke.sh` (backend + Mailpit running) | Every endpoint, plus the email reaching the inbox |
| iOS live flow | see below (backend + Mailpit running) | Browse → enquire → email in Mailpit |

```sh
cd ios && TEST_RUNNER_LIVE_BACKEND=1 xcodebuild test -project Catalogue.xcodeproj -scheme Catalogue \
  -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CatalogueUITests/LiveBackendUITests
```

If more than one iPhone 16 simulator is installed, add `,OS=<version>` to the destination.

## Project layout

```
backend/   Fastify API — src/{http,services,ports,adapters,domain}, test/
ios/Core/  Swift package: models, API client, repository, view models (+ tests)
ios/App/   Thin SwiftUI screens and components
ios/UITests/
scripts/   End-to-end smoke test
docs/      Plan
```
