#!/usr/bin/env bash
#
# Entry point of the demo "machine" container (docker-compose.yml): adds
# itself to the server the way install-agent.sh does (an install token from
# createEnrollment, redeemed with enroll — docs/FLOWS.md §1), then runs the
# agent runner. No Claude token here: set it in the panel ("Set token").
set -euo pipefail

SERVER_URL="${SERVER_URL:?SERVER_URL is required}"
MACHINE_NAME="${MACHINE_NAME:-demo-machine}"
STATE_DIR="${HOME}/.roundtable"
TOKEN_FILE="${STATE_DIR}/machine-token"
CONFIG_FILE="${STATE_DIR}/config.env"
mkdir -p "$STATE_DIR" "${HOME}/workspace"

post() {
  curl -sS --fail-with-body -X POST "${SERVER_URL%/}/$1" \
    -H 'Content-Type: application/json' --data "$2"
}

echo "Waiting for the server at ${SERVER_URL}..."
until curl -s -o /dev/null -X POST "${SERVER_URL%/}/machine/latestRunnerVersion" \
  -H 'Content-Type: application/json' --data '{}'; do
  sleep 2
done

# A token from an earlier run stays valid unless the database was reset.
if [[ -f "$TOKEN_FILE" ]] &&
  ! post machine/identify "{\"token\":\"$(cat "$TOKEN_FILE")\"}" >/dev/null 2>&1; then
  echo "The saved machine token is no longer known to the server — enrolling again."
  rm -f "$TOKEN_FILE"
fi

if [[ ! -f "$TOKEN_FILE" ]]; then
  echo "Adding ${MACHINE_NAME} to the server..."
  command_json="$(post machine/createEnrollment "{\"name\":\"${MACHINE_NAME}\"}")"
  install_token="$(printf '%s' "$command_json" |
    sed -n 's/.*"enrollmentToken":"\([^"]*\)".*/\1/p')"
  post machine/enroll \
    "{\"enrollmentToken\":\"${install_token}\",\"hostname\":\"$(hostname)\"}" |
    tr -d '"[:space:]' > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
fi

cat > "$CONFIG_FILE" <<CONFIG
REGISTRATION_TOKEN=$(cat "$TOKEN_FILE")
SERVER_URL=${SERVER_URL}
WORKSPACE_ROOT=${HOME}/workspace
PERMISSION_PROMPT_TOOL_PATH=/usr/local/bin/roundtable-permission-prompt-tool
CLAUDE_EXECUTABLE=${HOME}/.local/bin/claude
CONFIG
chmod 600 "$CONFIG_FILE"

echo "Starting the agent runner as ${MACHINE_NAME}."
AGENT_RUNNER_CONFIG_PATH="$CONFIG_FILE" exec /usr/local/bin/roundtable-agent-runner
