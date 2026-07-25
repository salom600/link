#!/usr/bin/env bash
# ============================================================================
# LinkOS — Polybar launcher script
# Kills existing polybar instances and starts the linkos bars.
# ============================================================================

set -euo pipefail

# Terminate existing instances
killall -q polybar 2>/dev/null || true

# Wait for shutdown
while pgrep -u "$(id -un)" -x polybar >/dev/null; do
    sleep 0.3
done

# Launch top bar
polybar -r linkos 2>&1 | tee -a "/tmp/polybar-linkos.log" &
disown

# Launch bottom dock
polybar -r linkos-dock 2>&1 | tee -a "/tmp/polybar-linkos-dock.log" &
disown

echo "Polybar started (linkos + linkos-dock)."
