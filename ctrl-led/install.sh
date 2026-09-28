#!/bin/bash
# Install ctrl-led (Massdrop CTRL status lights) and its Claude Code hooks.
# Safe to re-run. Usage: install.sh [path/to/ctrl-led.swift]
# Env overrides (for testing): CTRL_LED_BIN, CLAUDE_SETTINGS
set -euo pipefail

SRC_URL="https://raw.githubusercontent.com/Nodman/qmk_firmware/ctrl-spooner/keyboards/massdrop/ctrl/keymaps/spooner/host/ctrl-led.swift"
BIN="${CTRL_LED_BIN:-$HOME/.local/bin/ctrl-led}"
SETTINGS="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [[ -n "${1:-}" ]]; then
  cp "$1" "$tmp/ctrl-led.swift"
else
  curl -fsSL "$SRC_URL" -o "$tmp/ctrl-led.swift"
fi
mkdir -p "$(dirname "$BIN")"
xcrun swiftc -O "$tmp/ctrl-led.swift" -o "$BIN"
echo "Built $BIN"

python3 - "$SETTINGS" <<'EOF'
import json, os, shutil, sys

path = sys.argv[1]
settings = {}
if os.path.exists(path):
    backup = path + ".bak-ctrl-led"
    if not os.path.exists(backup):
        shutil.copy2(path, backup)
    with open(path) as f:
        settings = json.load(f)

hooks = settings.setdefault("hooks", {})

# Drop old ctrl-led hooks, keep everything else.
for event in list(hooks):
    groups = []
    for group in hooks[event]:
        group["hooks"] = [h for h in group.get("hooks", []) if "ctrl-led" not in h.get("command", "")]
        if group["hooks"]:
            groups.append(group)
    if groups:
        hooks[event] = groups
    else:
        del hooks[event]

hook = {"type": "command", "command": '"$HOME/.local/bin/ctrl-led" claude', "timeout": 5}
for event in ["SessionStart", "SessionEnd", "UserPromptSubmit", "Stop", "StopFailure"]:
    hooks.setdefault(event, []).append({"hooks": [hook]})
for event in ["PreToolUse", "PostToolUse", "PostToolUseFailure", "PermissionRequest", "PermissionDenied", "Notification"]:
    hooks.setdefault(event, []).append({"matcher": "*", "hooks": [hook]})

os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
print(f"Claude Code hooks set in {path}")
EOF
