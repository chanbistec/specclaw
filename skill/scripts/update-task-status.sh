#!/usr/bin/env bash
# Update a task's status in tasks.md
# Usage: update-task-status.sh <tasks.md> <task_id> <new_status>
# new_status: pending | in_progress | complete | failed

set -euo pipefail

TASKS_FILE="$1"
TASK_ID="$2"
NEW_STATUS="$3"

case "$NEW_STATUS" in
  pending)     MARKER="[ ]" ;;
  in_progress) MARKER="[~]" ;;
  complete)    MARKER="[x]" ;;
  failed)      MARKER="[!]" ;;
  *)
    echo "ERROR: Invalid status '$NEW_STATUS'. Use: pending|in_progress|complete|failed" >&2
    exit 1
    ;;
esac

# Use sed to find the line with the task ID and replace its status marker
if grep -q "\`$TASK_ID\`" "$TASKS_FILE"; then
  sed -i "s/^- \[.\] \`$TASK_ID\`/- $MARKER \`$TASK_ID\`/" "$TASKS_FILE"
  echo "OK: $TASK_ID → $NEW_STATUS"
else
  echo "ERROR: Task $TASK_ID not found in $TASKS_FILE" >&2
  exit 1
fi
