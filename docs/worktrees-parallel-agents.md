# Parallel agents with git worktrees

Goal: several agents work on one repository at the same time, each on its own task, without overwriting each other.

## Why separate checkouts

Two agents in one working directory share the same files, the same index and the same branch pointer. One agent's checkout, stash or reset changes what the other one sees. Failures are confusing because the code on disk changes under an agent that did nothing wrong.

A git worktree is a second working directory for the same repository. It has its own checked out branch and its own files, and it shares the object database, so it is cheap.

## The pattern

One task, one branch, one worktree, one agent.

```bash
git fetch origin
git worktree add ../work/fix-login-timeout -b fix/login-timeout origin/main
cd ../work/fix-login-timeout
```

When the pull request is merged:

```bash
cd ../..
git worktree remove work/fix-login-timeout
git branch -d fix/login-timeout
git worktree prune
```

## Rules

1. **Never run two agents on the same branch.** Git refuses to check out one branch in two worktrees. Treat that error as a rule, not as something to force.
2. **Branch from the latest main branch.** Fetch first. Rebase before you open the pull request so the review sees only your change.
3. **Keep worktrees outside the repository folder, or ignore the folder.** If they live inside it, add the folder to `.gitignore` so no agent commits another agent's files.
4. **Give each task a short name.** Use it for the branch and the folder. The name tells a human what each agent is doing.
5. **Do not share mutable state between worktrees.** Local databases, ports, build output and lock files should be per worktree or per task. Pick a port range per agent so two dev servers never bind the same port.
6. **Install dependencies per worktree.** A shared dependency folder is fast and fragile. A package cache that the package manager owns is fine.
7. **Expect lock file conflicts.** Parallel branches that both add a dependency will conflict. The second agent to merge rebases and regenerates the lock file instead of editing it by hand.
8. **Clean up.** Stale worktrees keep branches alive and hide real work. Remove a worktree when its pull request is merged or closed, and prune on a schedule.

## Coordination

- Give each agent a written task with a clear definition of done. Overlapping tasks cause conflicts that worktrees cannot fix.
- Split by area when you can, so two agents rarely edit the same file.
- Protected paths have one owner at a time. Say who in the issue.
- The reviewer agent checks out the pull request in its own worktree and never reuses an author's.

## What this does not solve

Worktrees stop file level collisions. They do not stop two agents from making incompatible design decisions. That still needs a clear plan and a review.
