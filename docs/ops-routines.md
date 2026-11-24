# Ops routines and guards

Goal: production problems reach an agent or a person without anyone staring at a dashboard.

## Two kinds of scheduled work

1. **Guards.** Small scripts on a timer. They detect one specific failure and write a status file. They do not decide anything.
2. **Routines.** Scheduled tasks for an agent. A routine reads the status files, looks at the situation and acts or escalates.

Keeping them apart matters. A guard is boring and testable. A routine uses judgment and can change over time. The status file is the contract between them.

## Why a guard exists

A real failure shaped like this started the practice. The balance on an LLM provider account reached zero. Every inference call returned a "balance exhausted" error. The app stayed up, the health check stayed green, and chat failed for days before anyone noticed.

Plain uptime checks do not catch that. The guard does two independent things:

1. It probes the same endpoint, model and credential that the app uses, with a one token request.
2. It counts recent error lines in the app log. This catches failures that a healthy probe misses, such as a broken tool loop.

## Behavior to copy

- **Alert on the first failure.** Then send at most one reminder per window. Alerting on every request creates noise that people learn to ignore.
- **Log one line on recovery.** The status file goes back to healthy.
- **Always write the status file.** Notification is optional and controlled by the environment. With no webhook configured the guard only logs, and the routine still reads the file.
- **Keep a lookback that outlives the reader.** If a routine reads the status file twice a day, a failure that appears and disappears between reads must still be visible. Keep the last failure in the file for a full day.
- **Test modes that never touch production state.** Provide a flag that injects the failure signature, so you can drill the whole alert path.
- **Hard rule: never log the credential.** Reduce provider error bodies to a code and a short message before logging.

## Secrets

- Read every secret from the environment.
- If the script runs from cron, put variables in a root owned file with mode 0600 and source it. Keep that file out of the repository.
- Never write the credential to disk from inside the script.

## A routine that reads the guard

A routine does not need to be clever. A good first version:

1. Run twice a day.
2. Read the status files of every guard.
3. If any state is failing, open an issue with the reason and the time it started.
4. If everything is healthy, write nothing.

Add routines slowly. Each one is a new thing that can be wrong at three in the morning.

## Example

`scripts/llm-guard.example.sh` is a complete generic guard. Read its header for the environment variables. Run it once by hand with real values before you put it in cron.

```bash
export LLM_BASE_URL="https://llm.example.com/v1/chat/completions"
export LLM_MODEL="your-model"
export LLM_API_KEY="set-this-from-your-secret-store"
./scripts/llm-guard.example.sh
cat /tmp/llm-guard/status.json
```

## Other guards worth having

Any dependency that can fail without an error page deserves one:

- a paid API balance or quota
- a certificate expiry date
- a backup that stopped running
- disk usage on the host
- an integration that depends on a session which can expire

Each one is a short script, a status file and a line in a routine.
