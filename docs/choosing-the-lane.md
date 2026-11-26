# Choosing the lane: orchestrated team or direct session

An orchestrated team of agents buys independent review at the price of latency. Each handoff starts a session that reads its context again, the same test suite runs once per role, work waits between stages, and the orchestrator has failures of its own. Route each change by its risk instead of sending everything through the same pipeline.

## Two lanes

| What the change touches | Lane |
|---|---|
| Money, keys, signing, contracts, authentication, privacy, limits a user relies on | The orchestrated team, with quality and security review |
| Interface, copy, documentation, tests | A direct session with the person, plus exactly one independent review before merge |

A change that touches both goes to the first lane. When in doubt, take the first lane.

The direct lane also suits work that needs fast iteration with a person, such as design. A person still decides every merge in both lanes.

## Test scope per role

The author runs the checks that cover the files they changed. The reviewer runs the full suite once on the head to be merged. Running the full suite in both roles doubles the slowest step without adding a control, because the reviewer's run is the one that gates the merge.

If a change has no reviewer, the author runs the full suite.
