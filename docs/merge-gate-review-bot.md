# The independent reviewer pattern

Goal: agents merge their own work with no human in the loop, and a second identity still has to approve every change.

## The problem

Merged code on the main branch builds and runs on a production server with elevated privileges. If branch protection requires zero reviews, the only gates between a push and that server are your automated checks.

Turning on "one approving review" is not enough by itself. If every agent pushes with the same identity, the host forbids self approval and every merge deadlocks.

## The decision

1. Create a **dedicated reviewer identity**. Use a machine user, which is a normal account that only automation uses.
2. Give it a **fine grained token** scoped to exactly one repository with exactly one permission, which is read and write on pull requests. That is enough to read and approve. It is not enough to push code or change settings.
3. Invite the machine user as an outside collaborator with write access. Approvals require write access.
4. Turn on branch protection for the main branch:
   - one approving review required
   - dismiss stale reviews when new commits are pushed
   - require approval of the most recent push
   - keep your automated checks required, including a secret scan
   - apply the rules to administrators too
5. Deliver the token as a secret **only to the reviewer role**, as an environment variable in that role's runtime. Authoring agents must not be able to reach it. Separation of duties comes from credential reach, not from good intentions.

## Merge procedure

1. The author agent opens a pull request.
2. CI goes green.
3. The reviewer agent reviews the diff and approves through the machine user.
4. The author agent merges.

For protected paths the reviewer is mandatory and the description must state the sign off.

## What went wrong on the way

- **A GitHub App was the first attempt and it failed.** The app could submit an approval, but the host did not count app approvals toward the required number. The pull request stayed at "review required". The gate was switched back the same minute and replaced by the machine user. Lesson: run an end to end drill before you rely on any gate.
- **Code owner rules and a second personal token also fail.** Apps cannot satisfy code owner requirements, and the host blocks self approval from the author identity regardless of token.
- **A classic token is too broad.** It grants code write as a bundle. A fine grained token can be limited to pull requests.

## Approve last

Two settings handle pushes after approval. They leave a gap for pushes before approval:

- A push that lands before the approval is submitted can be covered by that approval with no dismissal event.
- The approval check looks at submission time, not at what was verified.

The discipline that closes the gap:

- push branch updates first, then request approval
- never push between approval and merge
- the approver pins the exact head commit in the review text
- if the pinned commit and the review's commit differ, the approval is invalid and a new review is requested

## Healing dismissed approvals

A push dismisses an approval, and nothing recreates the review task, so a pull request can sit at "review required" for hours.

A scheduled sweep, about hourly, finds open pull requests with a dismissed reviewer approval. It requeues a mechanical re-approval only when the current patch is byte identical to the patch that was approved. Any change to the diff needs a full review. The sweep is read only. It never approves and never merges.

## Detecting drift

Settings can be turned off and on again by an owner. A scheduled workflow, about every 30 minutes and on pushes to the main branch, checks two things:

- merges with zero valid approvals at merge time
- any difference from the baseline settings above

It reports findings in a dedicated issue. Keep a watermark so the same window is not reported twice.

## When the author and the reviewer are the same role

If one role both authors a change and holds the reviewer credential, the approval is only a mechanical gate. Require a named second reviewer in the pull request for those changes. Disclose the situation in the description. Revisit hiring a second reviewer agent when this happens often.

## If the token leaks

The worst case is approval of pull requests in one repository, because the token cannot push code. Revoke it in the machine user's settings, remove the collaborator if needed, create a new token and rotate the stored secret. Set an expiry of at most one year and rotate before it.

## Rollback

Setting the required review count back to zero undoes the gate. Document it as the way out of any future gate failure.

## Acceptance drill

Do not flip the gate until one pull request has gone through the full path: authored by an agent identity, approved by the reviewer identity, approval counted by the host, merged without an administrator override.
