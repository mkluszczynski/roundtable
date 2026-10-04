#!/usr/bin/env bash
#
# Installs the roundtable agent-runner daemon as a systemd service on this
# machine. See docs/FLOWS.md §1–3.
#
# This script is self-executing: it downloads a prebuilt agent-runner binary
# from the server rather than building one from source, so the target
# machine needs no Dart SDK and no checkout of this repo.
#
# Usage:
#   curl -fsSL <script-url>/install-agent.sh | sudo bash -s -- \
#       --token <TOKEN> --server <SERVER_URL> --script-url <SCRIPT_URL> \
#       [--name <MACHINE_NAME>] [--claude-token <CLAUDE_CODE_OAUTH_TOKEN>] \
#       [--claude-path </path/to/claude>] [--extra-path <dir[:dir...]>]
#
# --server is the API server the agent connects to at runtime.
# --script-url is where this script (and the agent-runner binary it fetches)
# were served from — the panel fills in both automatically.
#
# The registration token is shown once by the panel when you register a
# machine, and is written to /etc/agent-runner/config.env (mode 600) — never
# into the systemd unit file, so it doesn't show up in `systemctl status`/`ps`.

set -euo pipefail

SERVICE_NAME="agent-runner"
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
CONFIG_DIR="/etc/agent-runner"
CONFIG_PATH="${CONFIG_DIR}/config.env"
BIN_PATH="/usr/local/bin/roundtable-agent-runner"
PERMISSION_PROMPT_BIN_PATH="/usr/local/bin/roundtable-permission-prompt-tool"
SERVICE_USER="roundtable-agent"
# Bare clones + per-task worktrees live here (docs/ARCHITECTURE.md). Must be
# owned by SERVICE_USER and outside /etc (config.env is 600, this isn't).
DATA_DIR="/var/lib/agent-runner"
WORKSPACE_DIR="${DATA_DIR}/workspace"
# In-panel updates: the daemon (unprivileged, NoNewPrivileges) can't replace
# its own root-owned binaries, so it writes UPDATE_FLAG_PATH instead and a
# root-side systemd path unit runs UPDATER_PATH to re-download them.
UPDATE_FLAG_PATH="${DATA_DIR}/update-requested"
UPDATER_PATH="/usr/local/bin/roundtable-agent-update"
UPDATE_SERVICE_NAME="agent-runner-update"
UPDATE_SERVICE_PATH="/etc/systemd/system/${UPDATE_SERVICE_NAME}.service"
UPDATE_PATH_UNIT_PATH="/etc/systemd/system/${UPDATE_SERVICE_NAME}.path"

TOKEN=""
SERVER=""
SCRIPT_URL=""
MACHINE_NAME=""
CLAUDE_TOKEN=""
CLAUDE_PATH_OVERRIDE=""
# Extra PATH directories for the agent (e.g. /opt/flutter/bin), so tasks
# can run a project's analyzer/tests. Kept across re-installs via config.env.
EXTRA_PATH=""

usage() {
  cat >&2 <<EOF
Usage: $0 --token <TOKEN> --server <SERVER_URL> --script-url <SCRIPT_URL> [--name <MACHINE_NAME>] [--claude-token <TOKEN>] [--claude-path </path/to/claude>] [--extra-path <dir[:dir...]>]
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
    --script-url)
      SCRIPT_URL="${2:-}"
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
    --claude-path)
      CLAUDE_PATH_OVERRIDE="${2:-}"
      shift 2
      ;;
    --extra-path)
      EXTRA_PATH="${2:-}"
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

if [[ -z "$TOKEN" || -z "$SERVER" || -z "$SCRIPT_URL" ]]; then
  echo "install-agent: --token, --server and --script-url are required" >&2
  usage
  exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
  echo "install-agent: must be run as root (try: sudo bash ...)" >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "install-agent: systemctl not found — this script only supports Linux with systemd" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "install-agent: curl not found — install curl first" >&2
  exit 1
fi

PLATFORM="$(uname -sm)"
if [[ "$PLATFORM" != "Linux x86_64" ]]; then
  echo "install-agent: unsupported platform \"$PLATFORM\" — the prebuilt agent-runner binary currently only targets Linux x86_64" >&2
  exit 1
fi

echo "Installing agent-runner${MACHINE_NAME:+ for machine \"$MACHINE_NAME\"}..."

# Stop any existing service before overwriting its binary, so re-running
# this script (e.g. to upgrade or re-point at a new server) is safe.
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
  echo "Stopping existing ${SERVICE_NAME} service..."
  systemctl stop "$SERVICE_NAME"
fi

echo "Downloading agent-runner and permission-prompt-tool binaries from ${SCRIPT_URL}..."
TMP_BIN="$(mktemp)"
TMP_PERMISSION_BIN="$(mktemp)"
trap 'rm -f "$TMP_BIN" "$TMP_PERMISSION_BIN"' EXIT
curl -fsSL "${SCRIPT_URL%/}/agent-runner-bin" -o "$TMP_BIN"
curl -fsSL "${SCRIPT_URL%/}/permission-prompt-tool-bin" -o "$TMP_PERMISSION_BIN"

echo "Installing binaries to ${BIN_PATH} and ${PERMISSION_PROMPT_BIN_PATH}..."
install -m 755 "$TMP_BIN" "$BIN_PATH"
install -m 755 "$TMP_PERMISSION_BIN" "$PERMISSION_PROMPT_BIN_PATH"

if ! id -u "$SERVICE_USER" >/dev/null 2>&1; then
  echo "Creating system user ${SERVICE_USER}..."
  # --home-dir (without --create-home) just records this as the account's
  # home dir in /etc/passwd, so systemd exports $HOME=$DATA_DIR for the unit
  # below without an explicit Environment= line — needed because `claude`
  # keeps its own config/credentials under $HOME/.claude.
  useradd --system --no-create-home --home-dir "$DATA_DIR" \
    --shell /usr/sbin/nologin "$SERVICE_USER"
elif [ "$(getent passwd "$SERVICE_USER" | cut -d: -f6)" != "$DATA_DIR" ]; then
  # Accounts created by older installs point $HOME at a directory that
  # doesn't exist, so `claude` fails to create ~/.claude/plans.
  echo "Updating ${SERVICE_USER} home directory to ${DATA_DIR}..."
  usermod --home "$DATA_DIR" "$SERVICE_USER"
fi

echo "Creating workspace directory ${WORKSPACE_DIR}..."
mkdir -p "$WORKSPACE_DIR"
chown -R "${SERVICE_USER}:${SERVICE_USER}" "$DATA_DIR"

# `claude` needs to be reachable by ${SERVICE_USER} at task-run time, not by
# whoever happens to be running this install script. Reusing a claude
# installed under a human user's home (nvm/npm's default) would mean
# ${SERVICE_USER} — a separate, unprivileged system account (docs/FLOWS.md §1–3)
# with no membership in that user's groups — has to be granted
# cross-user filesystem access just to traverse into it, which is brittle
# (breaks again on the next nvm/node upgrade, since the resolved path
# changes) and unnecessarily broad. Instead, give the service account its
# own install, fully self-contained under its own $HOME ($DATA_DIR) — no
# permission grants into anyone else's home directory required.
SERVICE_CLAUDE_BIN="${DATA_DIR}/.local/bin/claude"
CLAUDE_BIN=""

if [[ -n "$CLAUDE_PATH_OVERRIDE" ]]; then
  # An operator-provided path (e.g. a system-wide or enterprise-managed
  # install) — used as-is, no auto-install attempted.
  CLAUDE_BIN="$CLAUDE_PATH_OVERRIDE"
  if sudo -u "$SERVICE_USER" test -x "$CLAUDE_BIN" 2>/dev/null; then
    echo "Using claude CLI at ${CLAUDE_BIN} (--claude-path)"
  else
    echo "install-agent: warning: --claude-path ${CLAUDE_BIN} is not" \
      "executable by ${SERVICE_USER} — check its permissions, then" \
      "'systemctl restart ${SERVICE_NAME}'." >&2
  fi
elif sudo -u "$SERVICE_USER" test -x "$SERVICE_CLAUDE_BIN" 2>/dev/null; then
  # Already installed for this account by a previous run of this script.
  echo "claude CLI already installed for ${SERVICE_USER} at ${SERVICE_CLAUDE_BIN}"
  CLAUDE_BIN="$SERVICE_CLAUDE_BIN"
else
  echo "Installing claude CLI for ${SERVICE_USER}..."
  if sudo -u "$SERVICE_USER" env HOME="$DATA_DIR" bash -c \
    'curl -fsSL https://claude.ai/install.sh | bash' \
    >/dev/null 2>&1 \
    && sudo -u "$SERVICE_USER" test -x "$SERVICE_CLAUDE_BIN" 2>/dev/null; then
    echo "Installed claude CLI at ${SERVICE_CLAUDE_BIN}"
    CLAUDE_BIN="$SERVICE_CLAUDE_BIN"
  else
    echo "install-agent: warning: could not install the claude CLI for" \
      "${SERVICE_USER} (no network access, or the installer changed) —" \
      "tasks will fail until this is fixed. Either re-run this script once" \
      "the machine has network access, or install claude for ${SERVICE_USER}" \
      "yourself (e.g. 'sudo -u ${SERVICE_USER} env HOME=${DATA_DIR} bash -c" \
      "\"curl -fsSL https://claude.ai/install.sh | bash\"') and re-run this" \
      "script, or pass --claude-path to point at an existing install," \
      "then 'systemctl restart ${SERVICE_NAME}'." >&2
  fi
fi

# A re-install without --extra-path keeps the directories set last time.
if [[ -z "$EXTRA_PATH" && -f "$CONFIG_PATH" ]]; then
  EXTRA_PATH="$(sed -n 's/^EXTRA_PATH=//p' "$CONFIG_PATH" | tail -n 1)"
fi
if [[ -n "$EXTRA_PATH" ]]; then
  IFS=':' read -r -a EXTRA_DIRS <<< "$EXTRA_PATH"
  for dir in "${EXTRA_DIRS[@]}"; do
    if ! sudo -u "$SERVICE_USER" test -d "$dir" 2>/dev/null; then
      echo "install-agent: warning: --extra-path ${dir} is not a directory" \
        "${SERVICE_USER} can read — tools in it won't be available to agents." \
        "Install SDKs outside your home directory (e.g. /opt)." >&2
    fi
  done
fi

echo "Writing ${CONFIG_PATH}..."
mkdir -p "$CONFIG_DIR"
{
  echo "REGISTRATION_TOKEN=${TOKEN}"
  echo "SERVER_URL=${SERVER}"
  echo "WORKSPACE_ROOT=${WORKSPACE_DIR}"
  echo "PERMISSION_PROMPT_TOOL_PATH=${PERMISSION_PROMPT_BIN_PATH}"
  echo "SCRIPT_URL=${SCRIPT_URL}"
  echo "UPDATE_FLAG_PATH=${UPDATE_FLAG_PATH}"
  if [[ -n "$CLAUDE_BIN" ]]; then
    echo "CLAUDE_EXECUTABLE=${CLAUDE_BIN}"
  fi
  if [[ -n "$CLAUDE_TOKEN" ]]; then
    echo "CLAUDE_CODE_OAUTH_TOKEN=${CLAUDE_TOKEN}"
  fi
  if [[ -n "$EXTRA_PATH" ]]; then
    echo "EXTRA_PATH=${EXTRA_PATH}"
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
WorkingDirectory=${DATA_DIR}
Environment=HOME=${DATA_DIR}
$(
  # The self-installed \`claude\` above is a self-contained native binary
  # (no interpreter dependency), but a \`--claude-path\` pointing at an
  # nvm/npm install may be a Node script whose shebang interpreter (node)
  # lives alongside it — add its directory to PATH so that resolves too.
  # --extra-path directories come last; agents see them as available tools.
  UNIT_PATH_VALUE="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  if [[ -n "$CLAUDE_BIN" ]]; then
    UNIT_PATH_VALUE="${UNIT_PATH_VALUE}:$(dirname "$CLAUDE_BIN")"
  fi
  if [[ -n "$EXTRA_PATH" ]]; then
    UNIT_PATH_VALUE="${UNIT_PATH_VALUE}:${EXTRA_PATH}"
  fi
  echo "Environment=PATH=${UNIT_PATH_VALUE}"
)
User=${SERVICE_USER}
Group=${SERVICE_USER}
NoNewPrivileges=true
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Writing ${UPDATER_PATH}..."
cat > "$UPDATER_PATH" <<EOF
#!/usr/bin/env bash
# Re-downloads the agent-runner binaries from the server and restarts the
# service. Triggered by ${UPDATE_SERVICE_NAME}.path when the daemon writes
# ${UPDATE_FLAG_PATH} (the panel's "Update runner" button).
set -euo pipefail
SCRIPT_URL="\$(sed -n 's/^SCRIPT_URL=//p' "${CONFIG_PATH}")"
rm -f "${UPDATE_FLAG_PATH}"
TMP_BIN="\$(mktemp)"
TMP_PERMISSION_BIN="\$(mktemp)"
trap 'rm -f "\$TMP_BIN" "\$TMP_PERMISSION_BIN"' EXIT
echo "Downloading agent-runner binaries from \${SCRIPT_URL}..."
curl -fsSL "\${SCRIPT_URL%/}/agent-runner-bin" -o "\$TMP_BIN"
curl -fsSL "\${SCRIPT_URL%/}/permission-prompt-tool-bin" -o "\$TMP_PERMISSION_BIN"
systemctl stop "${SERVICE_NAME}"
install -m 755 "\$TMP_BIN" "${BIN_PATH}"
install -m 755 "\$TMP_PERMISSION_BIN" "${PERMISSION_PROMPT_BIN_PATH}"
systemctl start "${SERVICE_NAME}"
echo "agent-runner updated and restarted."
EOF
chmod 755 "$UPDATER_PATH"

echo "Writing ${UPDATE_SERVICE_PATH} and ${UPDATE_PATH_UNIT_PATH}..."
cat > "$UPDATE_SERVICE_PATH" <<EOF
[Unit]
Description=Roundtable Agent Runner updater

[Service]
Type=oneshot
ExecStart=${UPDATER_PATH}
EOF
cat > "$UPDATE_PATH_UNIT_PATH" <<EOF
[Unit]
Description=Watch for agent-runner update requests

[Path]
PathExists=${UPDATE_FLAG_PATH}

[Install]
WantedBy=multi-user.target
EOF
# A stale flag from before this install would trigger an immediate update.
rm -f "$UPDATE_FLAG_PATH"

echo "Starting ${SERVICE_NAME}..."
systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"
systemctl enable --now "${UPDATE_SERVICE_NAME}.path"

echo
echo "agent-runner installed and started."
systemctl status "$SERVICE_NAME" --no-pager || true
