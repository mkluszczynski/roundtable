#!/usr/bin/env bash
#
# Stops and removes the roundtable agent-runner daemon installed by
# install-agent.sh, and asks the server to revoke this machine's token so
# its status flips to offline immediately instead of waiting for the
# heartbeat timeout. See design doc §6.8.
#
# Usage:
#   ./scripts/uninstall-agent.sh [--server <URL>] [--token <TOKEN>]
#
# Both flags are optional — by default the token and server URL are read
# from /etc/agent-runner/config.env before it's removed. They're only
# needed if that file is already gone.

set -uo pipefail

SERVICE_NAME="agent-runner"
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
CONFIG_DIR="/etc/agent-runner"
CONFIG_PATH="${CONFIG_DIR}/config.env"
BIN_PATH="/usr/local/bin/roundtable-agent-runner"

TOKEN_ARG=""
SERVER_ARG=""

usage() {
  cat >&2 <<EOF
Usage: $0 [--server <URL>] [--token <TOKEN>]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      TOKEN_ARG="${2:-}"
      shift 2
      ;;
    --server)
      SERVER_ARG="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "uninstall-agent: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$EUID" -ne 0 ]]; then
  echo "uninstall-agent: must be run as root (try: sudo $0 ...)" >&2
  exit 1
fi

REGISTRATION_TOKEN=""
SERVER_URL=""
if [[ -f "$CONFIG_PATH" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_PATH"
  REGISTRATION_TOKEN="${REGISTRATION_TOKEN:-}"
  SERVER_URL="${SERVER_URL:-}"
fi
TOKEN="${TOKEN_ARG:-$REGISTRATION_TOKEN}"
SERVER="${SERVER_ARG:-$SERVER_URL}"

echo "Stopping and disabling ${SERVICE_NAME}..."
systemctl disable --now "$SERVICE_NAME" >/dev/null 2>&1 || true

DEREGISTERED=false
if [[ -n "$TOKEN" && -n "$SERVER" ]]; then
  echo "Deregistering with the server at ${SERVER}..."
  if curl -fsS -X POST "${SERVER%/}/machine/deregister" \
      -H 'Content-Type: application/json' \
      -d "{\"token\": \"${TOKEN}\"}" >/dev/null; then
    DEREGISTERED=true
  else
    echo "uninstall-agent: warning: failed to reach the server to deregister" \
      "— it will find out via the heartbeat timeout instead. Continuing" \
      "with local cleanup." >&2
  fi
else
  echo "uninstall-agent: warning: no token/server available (pass --token" \
    "and --server, or ensure ${CONFIG_PATH} still exists) — skipping" \
    "server-side deregistration. Continuing with local cleanup." >&2
fi

echo "Removing local files..."
rm -f "$UNIT_PATH"
rm -f "$CONFIG_PATH"
rmdir --ignore-fail-on-non-empty "$CONFIG_DIR" 2>/dev/null || true
rm -f "$BIN_PATH"
systemctl daemon-reload

echo
if [[ "$DEREGISTERED" == true ]]; then
  echo "agent-runner uninstalled; server-side deregistration succeeded."
else
  echo "agent-runner uninstalled locally; server-side deregistration was skipped or failed (see warning above)."
fi
