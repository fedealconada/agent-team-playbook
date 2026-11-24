#!/bin/bash
# Generic LLM provider guard.
#
# Why: when a provider balance runs out or a key is revoked, an app can fail
# silently for days. This script makes that failure loud.
#
# It does two independent checks:
#   1. Probe: one tiny chat completion against the same endpoint, model and
#      key the app uses.
#   2. Streak: count recent error lines in the app log.
#
# It keeps state so it alerts on the first failure and at most once per
# reminder window, and it logs one line when health returns.
#
# Every secret comes from the environment. Nothing is written to disk and
# nothing sensitive is logged.
#
# Required environment:
#   LLM_BASE_URL   chat completions endpoint, for example https://llm.example.com/v1/chat/completions
#   LLM_MODEL      model name
#   LLM_API_KEY    credential for that endpoint (never printed)
# Optional environment:
#   APP_LOG_FILE         log file with lines that contain "outcome=error" (default: unset, streak check skipped)
#   STATE_DIR            where state and status files go (default: /tmp/llm-guard)
#   ALERT_REPEAT_HOURS   reminder cadence while failing (default: 24)
#   STREAK_THRESHOLD     error lines that trip the streak alert (default: 5)
#   STREAK_LINES         how many trailing log lines to inspect (default: 300)
#   PROBE_TIMEOUT_SEC    probe timeout (default: 20)
#   ALERT_WEBHOOK_URL    where to POST an alert. Unset means log only.
#   ALERT_WEBHOOK_AUTH   full Authorization header value for the webhook
#
# Cron example, every 5 minutes:
#   */5 * * * * /usr/local/bin/llm-guard.sh >> /var/log/llm-guard.log 2>&1

set -u

: "${LLM_BASE_URL:?LLM_BASE_URL is required}"
: "${LLM_MODEL:?LLM_MODEL is required}"
: "${LLM_API_KEY:?LLM_API_KEY is required}"

STATE_DIR=${STATE_DIR:-/tmp/llm-guard}
ALERT_REPEAT_HOURS=${ALERT_REPEAT_HOURS:-24}
STREAK_THRESHOLD=${STREAK_THRESHOLD:-5}
STREAK_LINES=${STREAK_LINES:-300}
PROBE_TIMEOUT_SEC=${PROBE_TIMEOUT_SEC:-20}

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"
STATE_FILE="$STATE_DIR/state"
STATUS_FILE="$STATE_DIR/status.json"
BODY_FILE=$(mktemp)
trap 'rm -f "$BODY_FILE"' EXIT

now=$(date +%s)
failure=""

log() {
  printf '%s llm-guard: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1"
}

# 1. Probe. The request body is built here and the key is only sent as a header.
payload=$(printf '{"model":"%s","max_tokens":1,"messages":[{"role":"user","content":"ping"}]}' "$LLM_MODEL")
http_code=$(curl -s -o "$BODY_FILE" -w '%{http_code}' --max-time "$PROBE_TIMEOUT_SEC" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LLM_API_KEY" \
  -d "$payload" "$LLM_BASE_URL")

case "$http_code" in
  2*) ;;
  429) failure="probe_rate_limited_or_out_of_balance" ;;
  401|403) failure="probe_credential_rejected" ;;
  000) failure="probe_unreachable" ;;
  *) failure="probe_http_$http_code" ;;
esac

# 2. Streak. Independent of the probe, because a healthy probe can hide a broken tool loop.
if [ -z "$failure" ] && [ -n "${APP_LOG_FILE:-}" ] && [ -f "$APP_LOG_FILE" ]
then
  errors=$(tail -n "$STREAK_LINES" "$APP_LOG_FILE" | grep -c 'outcome=error')
  if [ "$errors" -ge "$STREAK_THRESHOLD" ]
  then
    failure="llm_error_streak"
  fi
fi

last_alert=0
last_state="ok"
if [ -f "$STATE_FILE" ]
then
  read -r last_state last_alert < "$STATE_FILE"
fi

notify() {
  log "ALERT $1"
  if [ -n "${ALERT_WEBHOOK_URL:-}" ]
  then
    if [ -n "${ALERT_WEBHOOK_AUTH:-}" ]
    then
      curl -s -o /dev/null --max-time 10 -X POST -H "Authorization: $ALERT_WEBHOOK_AUTH" \
        -H "Content-Type: application/json" -d "{\"alert\":\"$1\"}" "$ALERT_WEBHOOK_URL"
    else
      curl -s -o /dev/null --max-time 10 -X POST \
        -H "Content-Type: application/json" -d "{\"alert\":\"$1\"}" "$ALERT_WEBHOOK_URL"
    fi
  fi
}

if [ -n "$failure" ]
then
  repeat_after=$((ALERT_REPEAT_HOURS * 3600))
  if [ "$last_state" = "ok" ] || [ $((now - last_alert)) -ge "$repeat_after" ]
  then
    notify "$failure"
    last_alert=$now
  fi
  printf '%s %s\n' "failing" "$last_alert" > "$STATE_FILE"
  printf '{"state":"failing","reason":"%s","checked":%s}\n' "$failure" "$now" > "$STATUS_FILE"
else
  if [ "$last_state" = "failing" ]
  then
    log "recovered"
  fi
  printf '%s %s\n' "ok" "0" > "$STATE_FILE"
  printf '{"state":"ok","checked":%s}\n' "$now" > "$STATUS_FILE"
fi
