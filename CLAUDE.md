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
