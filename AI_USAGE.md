# AI usage

## Time spent

About 2 hours in total, within the brief's 2–3h time-box.

| Activity  | Time |
|-----------|------|
| Planning  | 20 min |
| Building  | 60 min |
| Testing   | 25 min |
| Reviewing | 15 min |
| **Total** | **2 h** |

## Tools and models

[Claude Code](https://claude.com/claude-code) (Claude Opus 5.5) in the terminal, for planning,
implementation, verification and review. Every commit is co-authored with it (see the
`Co-Authored-By` trailers).

## Agent instruction files

[`CLAUDE.md`](CLAUDE.md) is committed to the repo. It tells the agent to:

- propose before implementing and wait for approval;
- stay on the plan's critical path and suggest, not build, anything beyond it;
- record every assumption or cut in `DECISIONS.md`;
- never commit secrets;
- keep the `routes → services → ports` layering, keep Fake Store field names inside the adapter, and
  never call Fake Store from the client;
- keep logic in the iOS `Core` package, with thin SwiftUI views;
- add tests with every service or view-model change, using fakes rather than network calls.

## Plan

[`docs/PLAN.md`](docs/PLAN.md) was written before any code. It covers the stack, architecture, API,
how each acceptance criterion is interpreted, scope cuts, security basics and test strategy. The
build followed its steps in order, in small commits: scaffold, then the iOS client (`Core` package
first, then the screens), then the backend.

## Key prompts and moments

1. **Plan before code.** The brief went into `docs/PLAN.md` first: how each acceptance criterion is
   interpreted, what is cut, and how it is tested. Implementation started only once that was
   agreed.
2. **Guardrails before the agent wrote code.** `CLAUDE.md` set the architecture rules and "propose,
   wait for approval, then change", so the agent could not drift from the plan or skip tests.
3. **"Continue from the Status section in CLAUDE.md."** The backend was written on a machine that
   could not reach npm, so it was committed as explicitly *unverified*, with a step-by-step
   checklist in `CLAUDE.md`. That handover let the agent pick up verification later without guessing
   what had been run.
4. **"The account should be correct, please take care of that."** Before pushing, I made the agent
   prove which GitHub identity it would push and open the PR as, rather than assume.
5. **"Check if we are done with everything that is required and everything is working end to
   end."** The agent re-read the brief, re-ran everything from a fresh clone of GitHub `main`, and
   found that I had merged the PR the brief says to leave open. That is why this PR exists.

## Where the AI got something wrong, and how it was caught

- **A false pass in the smoke test.** The first run of `scripts/e2e-smoke.sh` reported that the
  valid enquiry was accepted. The server log showed seven POSTs and no `202`.
  - Cause 1: under bash 3.2 (the macOS default), the inline JSON bodies were brace-expanded into
    several malformed requests.
  - Cause 2: `check` compared only its first two arguments, so it passed by accident.
  - Caught by cross-checking a green result against the server log and the Mailpit inbox. Both are
    fixed, and `check` now fails on the wrong number of arguments.
- **Code written but never run.** The backend's tests had never been executed or type-checked. The
  first `tsc` run found a type error in the SMTP notifier test (the `sendMail` mock had no
  parameter). The tests passed at runtime, so only the type check caught it.
- **An insecure default.** The backend bound to `0.0.0.0`, exposing the dev server to the local
  network and VPN. The agent flagged it as a known gap; it now binds to `127.0.0.1` by default.
- **Respecting security controls instead of bypassing them.** Public npm is blocked on the company
  network, and the internal mirror quarantines packages for 7 days. Rather than look for a way
  around the block, dependencies were pinned to versions outside that window
  (`npm install --before`), and the lockfile was rewritten to public registry URLs. See
  [`DECISIONS.md`](DECISIONS.md#build--verification-notes).
