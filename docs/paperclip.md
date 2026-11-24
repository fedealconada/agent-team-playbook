# Running a team of agents with Paperclip

This page describes how one team uses Paperclip, an open source orchestrator for agent teams, to govern its agents. It only states what the team's own decision records and deployment notes say. The last section lists what is not covered.

## What it is used for

- **Agent governance.** A self-hosted Paperclip instance sits between the agents and the tools they are allowed to call. Tool access is controlled by policies, for example "allow", "block", "require approval", "trust rule" and "rate limit".
- **Approval cards.** When an agent calls a tool that requires approval, the instance creates an approval card and a human on the board decides. Granting an agent access to a connection can create one such rule per agent and per write tool.
- **Scheduled routines.** The instance runs routines on a schedule. One example is a production check that runs twice a day, reads a status file, and wakes an operations agent when something looks wrong.
- **Self-hosted, installed from npm.** The instance is installed through the project's managed installer from npm and updated often. The installer keeps the previous version, so a rollback means pinning the earlier version.

The repository's working rules say it plainly: the code is built by a team of AI agents, orchestrated with Paperclip or an equivalent.

## Routines read status files

The routine does not run checks itself. Small guard scripts on the server run on cron, every few minutes, and write a short status file with a state such as ok or failing, a count, and a note. The routine reads those files next to each other when it wakes up. See `docs/ops-routines.md` for the guard pattern.

Two practical points from this setup:

- **The status file is the alert.** A push target such as a webhook is optional and was left empty. A twice-daily read was enough, so the guards look back over a full day. That way a problem stays visible until the routine has read it.
- **The next step is decided in advance.** An alert goes to the operations agent first, and then escalates to a human owner according to a written decision tree.

## Contribute upstream, do not fork

The team decided that product-level changes to Paperclip are made as upstream contributions. The flow is a feature branch, an upstream pull request, a release, and then an npm update on the instance. The reasons, from the decision record:

- **Forking** means inheriting the full release and CI surface of a large monorepo, losing the simple npm update, and drifting with every release you skip. That cost is too high for a one-setting gap.
- **Patching the installed package** does not last. The next update wipes the patch, and the shipped bundle is minified, so a patch is hard to review or test.
- **A companion admin screen that calls the API** would need a board-level API key inside a web app. That is a step backward for secrets and blast radius, for a settings page the orchestrator should own.
- **Only filing an issue** is right for bugs you cannot fix. When a fix is already proposed and nobody is writing it, sending the pull request is faster.

Rules that follow from the decision:

- Tracking, specs and decision records stay in your own repository.
- The text of an upstream pull request stays neutral. No internal ticket ids and no operations context, because the upstream tracker is a public surface.
- Follow the upstream contribution guide for the size of the change. Small focused pull requests are the fast path, and the template asks for a duplicate search, the reasoning, and verification notes.
- Until a release ships the change you need, use the documented API fallback, even if it is lossy, and write the workaround down in the spec that is blocked by it.
- If upstream rejects a change you consider essential, the fallback is a fork, and that needs a new decision record first.

## A lesson about approval rules

A scheduled agent job that publishes something daily needed one human click per run, because two auto-created approval rules gated it. The documented way to turn off such a rule through the API returned an error because of an upstream bug. The working workarounds were lossy: clearing the rule's stored metadata, or deleting the rule so that a later re-grant recreates it.

The takeaway is to test that you can actually disable an approval rule before you build a routine that depends on it being disabled.

## Do not run the control plane next to a heavy test runner

On one small shared machine, the Paperclip control plane, the agent sessions and their isolated workspaces all ran on the same four cores as the browser test runner. When the load spiked to about twice the number of cores, the browser tests started failing on random timing-sensitive assertions, and every one of those tests passed when run alone. Give the test runner its own capacity, or raise the timeouts on purpose and keep the number of parallel agent sessions in check.

## Secrets stay in the vault

Credentials that agents or the application need live in the orchestrator's vault. They are not pasted into prompts and not committed to the repository. The same reasoning is behind rejecting the companion admin screen above: do not hand a powerful key to another application when the orchestrator can own the setting itself.

## What is not documented here

The source material does not cover these topics, so this page does not describe them:

- How agent roles are defined and what each role is allowed to do.
- How heartbeats work, including how often an agent wakes up and what it does when it does.
- How goals are set and tracked for agents.
- The adapters that connect the orchestrator to different agent runtimes, beyond the fact that they exist.

If you need those, read the upstream documentation for the version you install.
