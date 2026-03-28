# Build Engine — Orchestration Logic

This document describes how the OpenClaw agent orchestrates the SpecClaw build pipeline. The agent reads this and follows it step-by-step.

---

## Build Command Flow

When the user says `specclaw build <change>`:

### Step 1: Load Context

```
1. Read .specclaw/config.yaml → get model settings, git strategy, parallelism
2. Read .specclaw/changes/<change>/spec.md → requirements
3. Read .specclaw/changes/<change>/design.md → technical approach
4. Read .specclaw/changes/<change>/tasks.md → task list
5. Parse tasks into structured data (wave, id, title, files, depends, status)
```

### Step 2: Git Setup (if branch-per-change)

```bash
# Create feature branch
git checkout -b specclaw/<change-name>
```

### Step 3: Execute Waves

For each wave (in order):

```
1. Collect all pending tasks in this wave
2. Check dependencies — all depended tasks must be "complete"
3. For each task in the wave (up to parallel_tasks limit):
   a. Mark task as "in_progress" in tasks.md
   b. Prepare context payload (see agent-prompts.md → Build Agent)
   c. Spawn coding agent:
      sessions_spawn(
        runtime: "acp",        # or "subagent"
        task: <context_payload>,
        model: <config.models.coding>,
        mode: "run",
        label: "specclaw-<change>-<task_id>"
      )
   d. Track spawn in status.md
4. Wait for all agents in wave to complete (sessions_yield)
5. For each completed agent:
   a. If success → mark task "complete", git add + commit
   b. If failure → mark task "failed", log error
6. If any task failed → stop or continue based on config
```

### Step 4: Post-Build

```
1. Run build_command (if configured) — verify compilation
2. Run lint_command (if configured)
3. Run test_command (if configured)
4. Update status.md with results
5. Update .specclaw/STATUS.md dashboard
6. If auto_verify → trigger verification
7. Notify user via configured channel
```

---

## Parallel Execution Strategy

### Wave-Based Parallelism

Tasks are grouped into waves. Within a wave, tasks are independent and can run in parallel.

```
Wave 1: [T1, T2, T3]  ← spawn all 3 simultaneously
         ↓ wait all
Wave 2: [T4, T5]       ← spawn both (they depend on wave 1)
         ↓ wait all
Wave 3: [T6]           ← final integration/testing task
```

### Concurrency Control

- `config.build.parallel_tasks` limits concurrent agents (default: 3)
- If a wave has more tasks than the limit, batch them:
  ```
  Wave 1 has 5 tasks, limit is 3:
    Batch A: [T1, T2, T3] → wait → 
    Batch B: [T4, T5] → wait →
    Wave 2...
  ```

### Conflict Prevention

- Each task lists its files explicitly
- Tasks in the same wave MUST NOT touch the same files
- If file overlap detected → serialize those tasks (move one to next wave)

---

## Context Payload Construction

For each task, build the agent context:

```python
def build_context(change, task, config):
    context = f"""
# Task: {task.id} — {task.title}

## Project: {config.project.name}

## Specification (relevant sections)
{extract_relevant_spec(change.spec, task)}

## Design (relevant sections)  
{extract_relevant_design(change.design, task)}

## Task Details
{task.notes}

## Files to Modify
{task.files}

## Existing File Contents
{read_existing_files(task.files)}

## Constraints
- ONLY modify files listed above
- Follow existing patterns
- Write tests if test framework exists
- Commit: "specclaw({change.name}): {task.id} — {task.title}"
"""
    return context
```

### "Fresh Context" Principle

Each agent gets ONLY:
1. The specific task it's working on
2. Relevant spec sections (not the entire spec)
3. Relevant design sections (not the entire design)
4. Current content of files it needs to modify
5. Constraints and commit format

NO accumulated context from previous tasks. This prevents:
- Context window pollution
- Conflicting instructions
- Agents "remembering" wrong approaches from earlier tasks

---

## Error Handling

### Task Failure

```
If a task agent fails:
  1. Mark task as [!] failed in tasks.md
  2. Log the error in status.md
  3. Check if dependent tasks can still proceed:
     - If the failed task is depended upon → skip dependent tasks
     - If no dependents → continue with remaining tasks
  4. After all possible tasks complete → report failures to user
```

### Recovery

```
To retry failed tasks:
  specclaw build <change>  (automatically picks up [!] failed tasks)
  
To retry a specific task:
  specclaw build <change> --task T3
```

### Stuck Detection

```
If an agent runs longer than timeout_seconds:
  1. Kill the agent session
  2. Mark task as failed with "timeout"
  3. Continue with other tasks
```

---

## Git Integration

### branch-per-change Strategy

```bash
# Before build
git checkout -b specclaw/<change-name>

# After each task
git add <task-files>
git commit -m "specclaw(<change>): <task-id> — <task-title>"

# After all tasks complete + verify
git checkout main
git merge specclaw/<change-name>
git branch -d specclaw/<change-name>
```

### direct Strategy

```bash
# After each task
git add <task-files>
git commit -m "specclaw(<change>): <task-id> — <task-title>"
```

---

## Notification Payloads

### Build Started
```
🦞 **SpecClaw Build Started**
**Change:** <change-name>
**Tasks:** <count> across <waves> waves
**Model:** <coding model>
```

### Task Complete
```
✅ `<task-id>` — <task-title> (wave <n>)
```

### Task Failed
```
❌ `<task-id>` — <task-title>
Error: <error summary>
```

### Build Complete
```
🦞 **SpecClaw Build Complete**
**Change:** <change-name>
**Result:** <passed>/<total> tasks | <failed> failed
**Duration:** <time>
**Next:** Run `specclaw verify <change>` to validate
```
