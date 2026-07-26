#!/bin/bash
# Runs Obsidian confined to a single vault directory via macOS's
# sandbox-exec (Seatbelt). See README.md for background and caveats.
#
# Usage:
#   ./run-obsidian-sandboxed.sh /path/to/YourVault
#
# Optional environment overrides:
#   APP_PATH   defaults to /Applications/Obsidian.app
#   PROFILE    defaults to obsidian.sb next to this script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${PROFILE:-"$SCRIPT_DIR/obsidian.sb"}"
APP_PATH="${APP_PATH:-/Applications/Obsidian.app}"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 /path/to/YourVault" >&2
    exit 1
fi

VAULT_PATH="$(cd "$1" && pwd)"   # resolve to an absolute path

if [[ ! -d "$VAULT_PATH" ]]; then
    echo "Error: vault not found at $VAULT_PATH" >&2
    exit 1
fi

if [[ ! -f "$PROFILE" ]]; then
    echo "Error: sandbox profile not found at $PROFILE" >&2
    exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: Obsidian.app not found at $APP_PATH (set APP_PATH to override)" >&2
    exit 1
fi

echo "Vault:   $VAULT_PATH"
echo "App:     $APP_PATH"
echo "Profile: $PROFILE"

# --no-sandbox disables Chromium/Electron's own internal sandbox layer.
# It's required here: a sandboxed process cannot itself apply a further
# nested Seatbelt profile to its own child processes, which is what
# Electron's internal sandbox tries to do. Our outer sandbox-exec
# profile is providing the actual isolation, so this isn't a real
# loosening — see README.md for the longer version.
exec sandbox-exec \
    -D USER_HOME="$HOME" \
    -D VAULT_PATH="$VAULT_PATH" \
    -D APP_PATH="$APP_PATH" \
    -f "$PROFILE" \
    "$APP_PATH/Contents/MacOS/Obsidian" --no-sandbox
