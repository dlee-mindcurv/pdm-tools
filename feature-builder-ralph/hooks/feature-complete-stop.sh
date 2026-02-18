#!/bin/bash
set -euo pipefail

# Project-level Stop hook: detect feature completion via marker file
# Works alongside the ralph-wiggum plugin's stop hook (both run in parallel)

MARKER_FILE=".claude/ralph-completed"
STATE_FILE=".claude/ralph-loop.local.md"

# No marker = nothing to do (let plugin hook handle normally)
if [[ ! -f "$MARKER_FILE" ]]; then
  exit 0
fi

# Marker exists = feature is verified complete
# Delete state file so plugin hook finds nothing and allows exit
rm -f "$MARKER_FILE"
rm -f "$STATE_FILE"

echo "Feature completion marker detected — cleaning up Ralph loop state"
exit 0
