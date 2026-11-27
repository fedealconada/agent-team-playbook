# Skill and tool hygiene

Goal: each agent loads only what its job needs, and the skills it keeps get better from real failures.

## Check what a session actually loads

Do not trust the settings files. Read the init record that a headless run writes to its log. It lists the plugins, skills, tools and tool servers the session really received.

In one review, the worker settings disabled every plugin from the user settings file, and the workers still loaded well over a hundred skills. Plugins synced from an account or installed from a directory were not on that list. The run logs showed that only the team's own skills and a few general ones were ever invoked.

1. Compare the loaded skills with the skills invoked across past runs.
2. Disable what a role never uses. Name every plugin, including synced ones.
3. Read the first turn token count before and after the change.

## Match guards to every tool that can act

A pre tool hook only runs for the tool names in its matcher. A matcher that lists the shell tool and the file tools misses any other tool that runs a command, schedules work, starts another agent or sends something outward. New client versions add such tools.

1. After each client update, compare the tool list in the init record with the guard matcher.
2. Deny the tools a role does not need. A denied tool needs no guard rule.
3. Route every remaining command runner through the same command checks, and add a test for each. Widening the matcher is not enough if the guard script still branches on the old tool name.
4. Turn off inline shell in skills and commands for workers. It runs without a tool call, so the hook never sees it.
5. Block workers from writing skills, commands, subagents, hooks and tool server files. Keep reading and running allowed, because an orchestrator may ship its own skills in those folders.
6. Replay past tool calls from the run logs through the old and the new rules before installing. One such replay showed that a first draft would have blocked hundreds of legitimate calls.
7. Confirm in a live headless session that a blocked command is refused.

## Papercuts

The ideas in this section and the next two are adopted from published practice (Uber Engineering, "How Uber Evals 1 Million Agent Skill Invocations a Month"). They are not yet tested here.

A papercut is a short report that an agent files when a tool, a skill or a guard gets in the way: a blocked action that looks legitimate, a wrong instruction, or a command that fails silently.

```
Tried:    what the agent attempted
Expected: what should have happened
Happened: what did happen, with the short error
Fix:      what would solve it
```

- File it in the task tracker, unassigned, so a person triages it.
- The agent only reports. It never edits a guard or a skill to get past the problem.
- No secrets, client data or full logs in the report.
- Review the reports on a fixed day and group them by skill.

## Rejections become test cases

When a review requests changes, record which skill or rule should have prevented the finding. Keep the task input and the finding together. Once there are about ten real cases, run them with and without a proposed skill change before adopting it.

## Keep skills short and checkable

- Each step has one goal, a concrete command and a way to check the result.
- Each skill has a table of known failures and their fixes, filled from papercuts.
- Fold override documents back into the skill they correct. Two versions of one rule drift apart.
- Try removing text. A newer model may not need it.
