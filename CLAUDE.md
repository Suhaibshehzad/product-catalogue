# CLAUDE.md — agent instructions

Product catalogue PoC: iOS (SwiftUI) client + Node/TypeScript (Fastify) backend.
Full plan and assumptions: `docs/PLAN.md`. Read it before making changes.

## Ground rules

- **Do not implement without explicit instruction.** Propose, wait for approval, then change.
- Stay on the critical path from `docs/PLAN.md`. Do not add features outside it; suggest them instead.
- Every assumption or cut you make goes into `DECISIONS.md`.
- Never commit secrets. Configuration goes in `.env.example` with safe placeholder values.

## Architecture rules

- The iOS app talks **only** to our backend. Never call the Fake Store API from the client.
- Backend layering: `routes → services → ports`. Routes do HTTP + validation only; services hold
  business rules; adapters (Fake Store, SMTP) implement ports and are wired in one composition root.
- The backend owns the `Product` DTO. Do not leak Fake Store field names past the adapter.
- iOS: logic lives in the `Core` Swift package (models, API client, repository, view models).
  SwiftUI views stay thin and contain no networking.

## Conventions

- Backend: TypeScript strict mode, ES modules, Vitest. Errors as `{ error: { code, message } }`.
- iOS: Swift 6, SwiftUI, iOS 17+, `@Observable`, async/await, Swift Testing.
- Tests accompany every service/view-model change. Use fakes for ports, not network calls.

## Commands

- Backend: `cd backend && npm install && npm run dev` · tests: `npm test`
- Mail inbox (dev): `mailpit` → http://localhost:8025
- iOS core tests: `cd ios/Core && swift test`

## Status (remove this section before opening the PR)

Written on a machine that could not reach registry.npmjs.org, so the **backend has never been
installed, type-checked, tested or run**. iOS is built and tested against stub data only.
To finish on a machine with npm access:

1. `cd backend && npm install fastify @fastify/rate-limit nodemailer zod dotenv && npm install -D typescript tsx vitest @types/node @types/nodemailer`
   (records deps in package.json + lockfile — commit both; verify lockfile has no private registry URLs)
2. `npm run typecheck && npm test` — fix anything that fails.
3. `brew install mailpit && mailpit` (inbox at http://localhost:8025), then `cp .env.example .env && npm run dev`.
4. `scripts/e2e-smoke.sh` — every check must pass.
5. iOS live flow: `cd ios && TEST_RUNNER_LIVE_BACKEND=1 xcodebuild test -project Catalogue.xcodeproj -scheme Catalogue -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CatalogueUITests/LiveBackendUITests`
6. Then: README.md, DECISIONS.md, AI_USAGE.md (incl. time spent), push, open PR.
