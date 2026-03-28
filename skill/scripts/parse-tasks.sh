#!/usr/bin/env bash
# Parse tasks.md and output JSON for the build engine
# Usage: parse-tasks.sh <tasks.md>
# Output: JSON array of tasks with id, title, status, files, depends, wave

set -euo pipefail

TASKS_FILE="$1"

if [ ! -f "$TASKS_FILE" ]; then
  echo "ERROR: $TASKS_FILE not found" >&2
  exit 1
fi

# Parse tasks into JSON using awk
awk '
BEGIN {
  print "["
  first = 1
  wave = 0
  wave_desc = ""
}

/^### Wave/ {
  wave++
  gsub(/^### Wave [0-9]+ — /, "")
  gsub(/^### Wave [0-9]+/, "")
  wave_desc = $0
  next
}

/^- \[/ {
  # Extract status
  status = "pending"
  if ($0 ~ /\[x\]/) status = "complete"
  else if ($0 ~ /\[~\]/) status = "in_progress"
  else if ($0 ~ /\[!\]/) status = "failed"

  # Extract task ID and title
  match($0, /`T[0-9]+`/)
  if (RSTART > 0) {
    task_id = substr($0, RSTART+1, RLENGTH-2)
  } else {
    task_id = "T" NR
  }

  # Extract title (after the task ID and dash)
  title = $0
  sub(/^- \[.\] `T[0-9]+` — /, "", title)
  sub(/^- \[.\] /, "", title)

  # Reset per-task fields
  files = ""
  depends = ""
  estimate = ""
  notes = ""
  next_is_detail = 1
  next
}

next_is_detail && /^  - Files:/ {
  files = $0
  sub(/^  - Files: /, "", files)
  next
}

next_is_detail && /^  - Depends:/ {
  depends = $0
  sub(/^  - Depends: /, "", depends)
  next
}

next_is_detail && /^  - Estimate:/ {
  estimate = $0
  sub(/^  - Estimate: /, "", estimate)
  next
}

next_is_detail && /^  - Notes:/ {
  notes = $0
  sub(/^  - Notes: /, "", notes)
  next
}

# When we hit a non-detail line after a task, emit the task
next_is_detail && !/^  -/ && !/^$/ {
  if (task_id != "") {
    if (!first) printf ","
    first = 0
    printf "\n  {\"id\":\"%s\",\"title\":\"%s\",\"status\":\"%s\",\"wave\":%d,\"files\":\"%s\",\"depends\":\"%s\",\"estimate\":\"%s\"}", task_id, title, status, wave, files, depends, estimate
    task_id = ""
  }
  next_is_detail = 0
}

/^$/ {
  if (task_id != "" && next_is_detail) {
    if (!first) printf ","
    first = 0
    printf "\n  {\"id\":\"%s\",\"title\":\"%s\",\"status\":\"%s\",\"wave\":%d,\"files\":\"%s\",\"depends\":\"%s\",\"estimate\":\"%s\"}", task_id, title, status, wave, files, depends, estimate
    task_id = ""
    next_is_detail = 0
  }
}

END {
  if (task_id != "") {
    if (!first) printf ","
    printf "\n  {\"id\":\"%s\",\"title\":\"%s\",\"status\":\"%s\",\"wave\":%d,\"files\":\"%s\",\"depends\":\"%s\",\"estimate\":\"%s\"}", task_id, title, status, wave, files, depends, estimate
  }
  print "\n]"
}
' "$TASKS_FILE"
