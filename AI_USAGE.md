# AI usage

**Time spent:** about 2 hours or less in total, within the brief's 2–3h time-box.

## Tool

[Claude Code](https://claude.com/claude-code) (Claude Opus 5.5) in the terminal. Every commit is
co-authored with it (see the `Co-Authored-By` trailers).

## How it was used

1. **Plan first.** The brief was turned into [`docs/PLAN.md`](docs/PLAN.md): stack, architecture,
   API, how each acceptance criterion is interpreted, scope cuts and test strategy.
2. **Guardrails for the agent.** [`CLAUDE.md`](CLAUDE.md) holds the rules the agent must follow:
   propose before implementing, stay on the plan's critical path, record assumptions in
   `DECISIONS.md`, never commit secrets, keep the `routes → services → ports` layering, keep Fake
   Store out of the client, and write tests with every service or view-model change.
3. **Implementation in small, reviewable commits:** the scaffold, then the iOS client (`Core`
   package first, then the screens), then the backend.
4. **Verification on a second machine.** The backend was written on a machine that could not reach
   npm, so it was committed as explicitly *unverified*, with a checklist in `CLAUDE.md`. On a
   machine with registry access, the agent worked through the checklist: install, typecheck, tests,
   end-to-end smoke test against Mailpit, and the iOS live-backend UI test.

## Where human judgement mattered

- **Not trusting a green run.** The first smoke run reported that the valid enquiry was accepted,
  but the server log showed it never was. Tracing the script found that bash 3.2 (the macOS
  default) brace-expanded the JSON bodies and that `check` could pass by accident. Both are fixed,
  and passing runs are now cross-checked against the server log and the Mailpit inbox.
- **Respecting security controls instead of bypassing them.** Public npm is blocked on the company
  network, and the internal mirror quarantines packages for 7 days. Dependencies were pinned to
  versions outside that window (`npm install --before`) and the lockfile was rewritten to public
  registry URLs. Details are in [`DECISIONS.md`](DECISIONS.md#build--verification-notes).
- **Scope control.** Out-of-scope work (auth, checkout, AWS infrastructure, design system) stayed in
  the plan as suggestions rather than code.
