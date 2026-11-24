# Agent team conventions

Copy this file to `AGENTS.md`, then replace every bracketed part.

This repository is built by a team of AI agents. Every agent that works here follows these rules.

## Golden rules

1. **Never push directly to the main branch.** Work happens on a feature branch, then a pull request, then green CI, then an independent approval, then the author agent merges.
2. **The author never approves its own pull request.** The independent reviewer is [REVIEWER_IDENTITY]. Its credential is delivered only to the reviewer role.
3. **Protected paths need a written sign off in the pull request description.** Protected paths are [PROTECTED_PATHS, for example the database schema, public interface definitions, authentication, rate limits, payments and the CI configuration]. Everything else can merge once CI is green and the review is done.
4. **Credentials never enter the repository.** No tokens, no environment files, no secrets in code, logs or pull request descriptions. Use `.env.example` with placeholders only.
5. **One pull request has one purpose.** If a task needs more than about 300 changed lines, split it and say so in the issue.
6. **Destructive production actions need explicit human approval** unless a documented runbook step covers them.

## Engineering standards

- [LANGUAGE AND STRICTNESS, for example strict typing and no escape hatches without a comment that explains why].
- Every new code path ships with a test where a test is possible without a live database. Database behavior is covered by a seed script and manual smoke test notes in the pull request.
- Typecheck and tests must pass locally before you open a pull request.
- Match the existing style. Read three nearby files before you write a new one.
- Database access always goes through parameterized queries. Never build SQL by joining user input into a string.
- Asynchronous request handlers must catch their own errors or be wrapped by the shared helper. An unhandled rejection can terminate the process.

## Review discipline

- Push branch updates before you request approval. Never push between approval and merge.
- The approver records the exact commit that was reviewed. If the reviewed commit and the head commit differ, the approval does not count.
- After any new push, request review again.

## Repo map

Keep this table short and keep it true.

| Path | What lives here |
|---|---|
| [PATH] | [WHAT IT IS, and whether it is protected] |

## Public and private material

If this repository is public, specs here describe product behavior only. Internal tickets, decision records, company accounts and infrastructure details belong in a private repository. CI scans the documentation folders for those markers on every pull request.

## Language for machine readable files

Pick one canonical sentence that describes the project. Use it word for word in the README, the website and any file meant for language models. Consistency is what lets a model describe you correctly.

## Commit style

Conventional commits such as `feat:`, `fix:`, `docs:` and `chore:`. Present tense, one line. The pull request is the unit of review.

## Keep the playbook current

When working rules, review gates, routines, worktree practices or agent orchestration change, update the matching document in the team's private playbook during the same session. Generalize the lesson before writing it. Exclude secrets, client and project names, internal hosts, identifiers and local paths.

Commit the documentation change and tell the user what changed. Before pushing, verify that the origin repository is private. If the visibility check fails or the repository is public, stop and ask. Push only to that private origin.

## Commit attribution

Set the author identity for each task explicitly so a shared agent account does not receive another person's work by default. Follow the agreed coauthor trailer format for assisted work and preserve existing contributor credit. Approving or merging a pull request alone does not establish authorship.

For historical corrections, select exact commits and prepare an isolated preview. Preserve file contents, dates and merge authorship. Verify the rewritten graph and keep an original history backup. Obtain explicit approval before publishing a history rewrite and use a lease tied to the reviewed remote head.
