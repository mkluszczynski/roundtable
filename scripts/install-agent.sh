#!/usr/bin/env bash
#
# Installs the roundtable agent-runner daemon as a systemd service on this
# machine. See design doc §6.8.
#
# Usage:
#   ./scripts/install-agent.sh --token <TOKEN> --server <URL> \
#       [--name <MACHINE_NAME>] [--claude-token <CLAUDE_CODE_OAUTH_TOKEN>]
#
# The token is shown once by the panel when you register a machine, and is
# written to /etc/agent-runner/config.env (mode 600) — never into the
# systemd unit file, so it doesn't show up in `systemctl status`/`ps`.

set -euo pipefail

SERVICE_NAME="agent-runner"
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
CONFIG_DIR="/etc/agent-runner"
CONFIG_PATH="${CONFIG_DIR}/config.env"
BIN_PATH="/usr/local/bin/roundtable-agent-runner"
SERVICE_USER="roundtable-agent"

TOKEN=""
SERVER=""
MACHINE_NAME=""
CLAUDE_TOKEN=""

usage() {
  cat >&2 <<EOF
Usage: $0 --token <TOKEN> --server <URL> [--name <MACHINE_NAME>] [--claude-token <TOKEN>]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --token)
      TOKEN="${2:-}"
      shift 2
      ;;
    --server)
      SERVER="${2:-}"
      shift 2
      ;;
    --name)
      MACHINE_NAME="${2:-}"
      shift 2
      ;;
    --claude-token)
      CLAUDE_TOKEN="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "install-agent: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$TOKEN" || -z "$SERVER" ]]; then
  echo "install-agent: --token and --server are required" >&2
  usage
  exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
  echo "install-agent: must be run as root (try: sudo $0 ...)" >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "install-agent: systemctl not found — this script only supports Linux with systemd" >&2
  exit 1
fi

if ! command -v dart >/dev/null 2>&1; then
  echo "install-agent: dart not found on PATH — install the Dart SDK first" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_RUNNER_DIR="${REPO_ROOT}/roundtable_agent_runner"
CLIENT_DIR="${REPO_ROOT}/roundtable_client"

if [[ ! -d "$AGENT_RUNNER_DIR" || ! -d "$CLIENT_DIR" ]]; then
  echo "install-agent: expected to find roundtable_agent_runner and roundtable_client under ${REPO_ROOT}" >&2
  exit 1
fi

echo "Installing agent-runner${MACHINE_NAME:+ for machine \"$MACHINE_NAME\"}..."

# Stop any existing service before overwriting its binary, so re-running
# this script (e.g. to upgrade or re-point at a new server) is safe.
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
  echo "Stopping existing ${SERVICE_NAME} service..."
  systemctl stop "$SERVICE_NAME"
fi

echo "Building roundtable_agent_runner..."
# The full repo is a single pub workspace that also includes
# roundtable_flutter, which needs the Flutter SDK to resolve — not
# something this machine necessarily has. Build from a minimal, synthetic
# workspace containing just the two packages we need instead (same trick
# roundtable_server/Dockerfile uses), reusing the root pubspec.lock so
# dependency versions stay pinned to what's actually checked in.
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT
cp "${REPO_ROOT}/pubspec.lock" "$BUILD_DIR/"
cp -r "$AGENT_RUNNER_DIR" "$BUILD_DIR/roundtable_agent_runner"
cp -r "$CLIENT_DIR" "$BUILD_DIR/roundtable_client"
cat > "${BUILD_DIR}/pubspec.yaml" <<EOF
name: _
environment:
  sdk: ^3.12.2
workspace:
  - roundtable_agent_runner
  - roundtable_client
EOF
(
  cd "$BUILD_DIR"
  dart pub get
  cd roundtable_agent_runner
  dart build cli --target bin/roundtable_agent_runner.dart --output build
)

BUILT_BINARY="${BUILD_DIR}/roundtable_agent_runner/build/bundle/bin/roundtable_agent_runner"
if [[ ! -f "$BUILT_BINARY" ]]; then
  echo "install-agent: build did not produce a binary at ${BUILT_BINARY}" >&2
  exit 1
fi

echo "Installing binary to ${BIN_PATH}..."
install -m 755 "$BUILT_BINARY" "$BIN_PATH"

if ! id -u "$SERVICE_USER" >/dev/null 2>&1; then
  echo "Creating system user ${SERVICE_USER}..."
  useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"
fi

echo "Writing ${CONFIG_PATH}..."
mkdir -p "$CONFIG_DIR"
{
  echo "REGISTRATION_TOKEN=${TOKEN}"
  echo "SERVER_URL=${SERVER}"
  if [[ -n "$CLAUDE_TOKEN" ]]; then
    echo "CLAUDE_CODE_OAUTH_TOKEN=${CLAUDE_TOKEN}"
  fi
} > "$CONFIG_PATH"
chown root:root "$CONFIG_PATH"
chmod 600 "$CONFIG_PATH"

echo "Writing ${UNIT_PATH}..."
cat > "$UNIT_PATH" <<EOF
[Unit]
Description=Roundtable Agent Runner
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${BIN_PATH}
EnvironmentFile=${CONFIG_PATH}
User=${SERVICE_USER}
Group=${SERVICE_USER}
NoNewPrivileges=true
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Starting ${SERVICE_NAME}..."
systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

echo
echo "agent-runner installed and started."
systemctl status "$SERVICE_NAME" --no-pager || true
