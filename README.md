# Agent team playbook

Conventions for running a software project with a team of AI coding agents. They come from a real open source project that is built and operated this way. I generalized them so you can copy what fits and ignore the rest.

This is one team's working setup, not a standard. Every rule below exists because something went wrong or nearly did, and the reason is written next to the rule.

## What is in here

| File | What it covers |
|---|---|
| `AGENTS.example.md` | A working rules file you can drop into a repo and edit. Agents read it before they touch code. |
| `docs/merge-gate-review-bot.md` | How to let agents merge their own work while an independent identity still has to approve it. |
| `docs/ops-routines.md` | Scheduled agent routines, and a small guard that turns silent failures into alerts. |
| `docs/paperclip.md` | How a self-hosted Paperclip instance governs agents and runs routines, and why changes go upstream instead of into a fork. |
| `docs/choosing-the-lane.md` | Which changes go through the orchestrated team and which through a direct session, and who runs the full test suite |
| `docs/shared-agent-config.md` | How to share global rules, skills and MCP servers across multiple coding agent CLIs without duplicating files. |
| `docs/worktrees-parallel-agents.md` | How several agents work on one repository at the same time without colliding. |
| `scripts/llm-guard.example.sh` | A generic version of the guard. It reads every secret from environment variables. |

## The rules, and why they exist

1. **Agents merge their own pull requests, but never without an independent approval.** If CI is the only gate and merged code runs with host privileges, one mistaken or compromised agent can ship anything. Git hosts block self approval, so the reviewer needs its own identity. See the merge gate document.
2. **The reviewer identity is a machine user with a token that can approve and nothing else.** A GitHub App looked like the obvious choice and failed in a live test: its approvals were submitted but not counted toward the required reviews, so merges were refused. A machine user with a narrowly scoped token worked.
3. **Credentials never enter the repository, the logs or a pull request description.** Use placeholder files only. Run a secret scan in CI.
4. **One pull request has one purpose.** If a task needs more than about 300 changed lines, split it and say so in the issue. Small changes are the only thing a reviewer agent can verify reliably.
5. **Some paths are protected.** Schema, public interfaces, authentication, rate limits, payments and CI itself need an explicit sign off written in the pull request description.
6. **Approve last.** A push that lands before the approval is submitted can end up covered by that approval without any warning. Push first, request approval, then merge right away, and pin the exact commit that was reviewed.
7. **Approvals that a push dismissed get healed by a read only sweep.** The sweep only re-queues a review when the diff is byte identical to the one that was approved. It never approves and never merges.
8. **Silent failures get a guard.** When an LLM provider balance ran out, chat failed for days and nobody was told. A probe that checks the same endpoint the app uses, plus an error counter, makes that failure loud.
9. **Contribute upstream, do not fork your tools.** Patching an installed bundle is wiped by the next update, and a fork turns into a maintenance job. Send the change upstream and use a documented fallback until it ships.
10. **Keep public and private material apart.** Public docs describe product behavior only. Internal tickets, decisions and infrastructure details live in a private repository, and CI scans for those markers.
11. **Parallel agents get separate worktrees.** Two agents in one checkout overwrite each other.

## How to adapt this

1. Copy `AGENTS.example.md` to `AGENTS.md` and replace the bracketed parts with your own stack and protected paths.
2. Decide who the independent reviewer is. If you cannot give it a separate identity and a narrow credential, do not claim to have the gate.
3. Add the guard from `docs/ops-routines.md` for every external dependency that can fail without an error page, such as a paid API.
4. Start with the smallest version. One rule you enforce is worth more than ten you wrote down.

## Limits

- I did not measure how much each rule improves quality. The reasons given are what happened in practice.
- Removing humans from the merge path is a risk decision. Keep a documented human approval for destructive production actions.

## License

MIT. See `LICENSE`.
