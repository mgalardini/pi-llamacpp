#!/usr/bin/env bash
# Diagnose the llama.cpp "Connection error" issue.
# Run this on the affected (GPU) machine WHILE a server is up (server.json present).
# It checks what is listening, probes the HTTP endpoints, then fires 3 sequential
# chat completions (each a fresh connection) to try to reproduce the failure at the
# HTTP layer, bypassing pi entirely.
set -u

STATE_FILE="${LLAMACPP_STATE_FILE:-$HOME/.pi/llamacpp/server.json}"

if [ ! -f "$STATE_FILE" ]; then
  echo "No server.json at $STATE_FILE — is a server running? Start a request in pi first."
  exit 1
fi

PORT=$(grep -o '"port":[0-9]*' "$STATE_FILE" | grep -o '[0-9]*')
MODEL=$(grep -o '"modelId":"[^"]*"' "$STATE_FILE" | head -1 | sed 's/.*"modelId":"\([^"]*\)".*/\1/')
MODEL=${MODEL:-qwen-3.6-dense-4bit}
echo "PORT=$PORT  MODEL=$MODEL"
echo "--- server.json ---"
cat "$STATE_FILE"; echo

echo "--- what is listening on :$PORT ---"
(command -v lsof >/dev/null 2>&1 && lsof -nP -iTCP:"$PORT" -sTCP:LISTEN) || \
  (command -v ss >/dev/null 2>&1 && ss -ltnp "sport = :$PORT") || \
  echo "(no lsof/ss available)"

echo "--- endpoint status codes ---"
for ep in /health /v1/models /models /props; do
  printf '%s -> ' "$ep"
  curl -sS -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:$PORT$ep" || echo "curl failed: $?"
done

echo "--- 3 sequential chat completions (fresh connection each) ---"
req="{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":8}"
for i in 1 2 3; do
  printf '=== chat %s === ' "$i"
  curl -sS -o /dev/null -w 'http=%{http_code} time=%{time_total}s\n' \
    -H 'Content-Type: application/json' -H 'Authorization: Bearer llamacpp-local' \
    -d "$req" "http://127.0.0.1:$PORT/v1/chat/completions" || echo "curl failed: $?"
done
