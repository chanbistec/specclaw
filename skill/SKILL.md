---
name: specclaw
description: "Spec-driven development framework for OpenClaw. Propose features, generate specs, spawn coding agents, validate implementations."
metadata:
  openclaw:
    emoji: "🦞"
    requires:
      tools: ["exec", "sessions_spawn", "message"]
allowed-tools: ["exec", "read", "write", "edit", "sessions_spawn", "sessions_yield", "subagents", "message", "memory_search"]
---

# SpecClaw — Spec-Driven Development

## Overview

SpecClaw brings structured, spec-driven development to OpenClaw agents. It manages the full lifecycle: propose → plan → build → verify → archive.

## Directory Structure

When initialized (`.specclaw/` exists in project root):

```
.specclaw/
├── config.yaml          # Project configuration
├── STATUS.md            # Project dashboard (auto-generated)
└── changes/
    ├── <change-name>/
    │   ├── proposal.md  # Problem + solution + scope
    │   ├── spec.md      # Requirements + acceptance criteria
    │   ├── design.md    # Technical approach + file map
    │   ├── tasks.md     # Ordered tasks with status markers
    │   └── status.md    # Progress tracking
    └── archive/         # Completed changes
```

## Commands

The user triggers commands conversationally. Recognize these patterns:

### `specclaw init`
**Trigger:** "specclaw init", "initialize specclaw", "set up spec-driven development"

1. Create `.specclaw/` directory structure
2. Generate `config.yaml` from template (see `templates/config.yaml`)
3. Ask user for project name/description
4. Create initial `STATUS.md`
5. Add `.specclaw/` tracking to git

### `specclaw propose "<idea>"`
**Trigger:** "specclaw propose", "propose a change", "new feature proposal"

1. Create `.specclaw/changes/<slugified-name>/`
2. Generate `proposal.md` from template
3. Include: problem statement, proposed solution, scope, impact, open questions
4. Present proposal to user for review
5. Update `STATUS.md`

### `specclaw plan <change>`
**Trigger:** "specclaw plan", "plan the feature", "generate spec for"

1. Read the proposal
2. Analyze existing codebase (file structure, patterns, dependencies)
3. Generate:
   - `spec.md` — functional requirements, acceptance criteria, edge cases
   - `design.md` — technical approach, architecture, file changes map
   - `tasks.md` — ordered implementation tasks with dependencies
4. Present plan summary to user
5. Update status

### `specclaw build <change>`
**Trigger:** "specclaw build", "implement the feature", "start building"

**This is where OpenClaw shines:**

1. Read `tasks.md` for the change
2. For each task (or wave of independent tasks):
   a. Prepare context: spec + design + task description + relevant source files
   b. Spawn a coding agent via `sessions_spawn`:
      ```
      runtime: "acp" (or "subagent")
      task: <context + task instructions>
      model: <from config.yaml models.coding>
      ```
   c. Track progress in `status.md`
   d. On completion, validate output
3. After all tasks: run verification
4. Notify user via configured channel

**Parallel execution:** Tasks without dependencies can be spawned simultaneously. Check `tasks.md` for dependency markers (`depends: [task-id]`).

**Fresh context:** Each agent gets ONLY what it needs — no stale context from prior tasks. This is critical for quality.

### `specclaw verify <change>`
**Trigger:** "specclaw verify", "validate implementation", "check against spec"

1. Read `spec.md` acceptance criteria
2. Check each criterion against the implementation
3. Run tests if configured (`config.yaml test_command`)
4. Generate verification report
5. Update `status.md` with pass/fail per criterion
6. If failures: suggest remediation tasks

### `specclaw status`
**Trigger:** "specclaw status", "project status", "what's the progress"

1. Read all changes in `.specclaw/changes/`
2. Compile dashboard showing:
   - Active changes with progress %
   - Pending proposals
   - Recently archived
   - Overall project health
3. Update `STATUS.md`

### `specclaw archive <change>`
**Trigger:** "specclaw archive", "mark as done", "archive the change"

1. Verify change is complete (all tasks done, verification passed)
2. Move to `.specclaw/changes/archive/YYYY-MM-DD-<change-name>/`
3. Update `STATUS.md`
4. Optionally create git tag

### `specclaw auto`
**Trigger:** "specclaw auto", "autonomous mode", "auto-build"

1. Check `STATUS.md` for next actionable item
2. If proposal exists without plan → generate plan
3. If plan exists without implementation → build
4. If built without verification → verify
5. Respect `config.yaml` limits (max_tasks_per_run)
6. Notify user of results

## Task Format in tasks.md

```markdown
## Tasks

### Wave 1 (no dependencies)
- [ ] `T1` — Create theme context provider
  - Files: `src/contexts/ThemeContext.tsx`
  - Estimate: small
- [ ] `T2` — Add CSS custom properties
  - Files: `src/styles/variables.css`
  - Estimate: small

### Wave 2 (depends on Wave 1)
- [ ] `T3` — Create toggle component
  - Files: `src/components/ThemeToggle.tsx`
  - Depends: T1
  - Estimate: small

### Wave 3 (depends on Wave 2)
- [ ] `T4` — Integration tests
  - Files: `tests/theme.test.ts`
  - Depends: T1, T2, T3
  - Estimate: medium
```

Status markers:
- `[ ]` — pending
- `[~]` — in progress
- `[x]` — complete
- `[!]` — failed (needs remediation)

## Agent Context Preparation

When spawning a coding agent for a task, build the context payload as:

```
# Task: <task title>

## Context
<relevant sections from spec.md>

## Design
<relevant sections from design.md>

## Task Details
<task description from tasks.md>

## Files to Modify
<list from task>

## Constraints
- Follow existing code patterns
- Write tests for new functionality
- Do not modify files outside the listed scope
```

## Configuration Reference

See `templates/config.yaml` for the full config schema.

Key settings:
- `models.planning` — model for proposals, specs, design (default: opus)
- `models.coding` — model for implementation (default: codex)
- `models.review` — model for verification (default: sonnet)
- `git.strategy` — "branch-per-change" or "direct"
- `notifications.channel` — where to send updates
- `automation.max_tasks_per_run` — limit for auto mode

## Best Practices

1. **Keep proposals focused** — one change per proposal, small scope
2. **Review specs before building** — garbage in, garbage out
3. **Wave-based execution** — group independent tasks, respect dependencies
4. **Fresh context always** — never let agents accumulate stale context
5. **Verify early** — run verification after each wave, not just at the end
