# 🦞 SpecClaw

**Spec-driven development for OpenClaw agents.**

SpecClaw is a lightweight framework that brings structured, spec-driven development to OpenClaw. Write specs, let agents build — with full traceability from requirement to implementation.

## Why SpecClaw?

AI coding agents are powerful but lose context fast. Existing SDD frameworks (GSD, OpenSpec, BMAD) work great with IDE-based tools, but none leverage OpenClaw's unique capabilities:

- **Subagent orchestration** — spawn parallel coding agents per task
- **Multi-model routing** — Opus plans, Codex/Claude Code implements, Sonnet reviews
- **Messaging integration** — Discord/Telegram approvals and status updates
- **Cron automation** — "build one feature per night" mode
- **Memory continuity** — cross-session context that survives restarts

## How It Works

```
You: "Add user authentication with OAuth2"

SpecClaw:
  1. Creates proposal + spec + design + tasks
  2. You review and approve (chat or Discord buttons)
  3. Spawns coding agents for each task
  4. Validates implementation against spec
  5. Archives completed work, updates dashboard
```

## Quick Start

### As an OpenClaw Skill

```bash
# Install from ClawHub
clawhub install specclaw

# Initialize in your project
# (Tell your OpenClaw agent)
> specclaw init
```

### Manual Setup

Copy the `skill/` directory into your OpenClaw workspace skills folder.

## Project Structure

When initialized in a project, SpecClaw creates:

```
.specclaw/
├── config.yaml          # Project config (models, git strategy, etc.)
├── STATUS.md            # Overall project dashboard
└── changes/
    └── <feature-name>/
        ├── proposal.md  # Why + what (human reviews)
        ├── spec.md      # Requirements + acceptance criteria
        ├── design.md    # Technical approach
        ├── tasks.md     # Implementation tasks (ordered, tracked)
        └── status.md    # Auto-tracked progress per change
```

## Commands

| Command | Description |
|---------|-------------|
| `specclaw init` | Initialize SpecClaw in a project |
| `specclaw propose "<idea>"` | Create a new change proposal |
| `specclaw plan <change>` | Generate spec + design + tasks from proposal |
| `specclaw build <change>` | Execute tasks via coding agents |
| `specclaw verify <change>` | Validate implementation against spec |
| `specclaw status` | Show project dashboard |
| `specclaw archive <change>` | Archive completed change |
| `specclaw auto` | Autonomous mode — pick next task and build |

## Workflow

### 1. Propose
```
> specclaw propose "add dark mode support"
```
Creates `.specclaw/changes/add-dark-mode/proposal.md` with:
- Problem statement
- Proposed solution
- Scope and impact
- Open questions

### 2. Plan
```
> specclaw plan add-dark-mode
```
Generates from the proposal:
- `spec.md` — Requirements, acceptance criteria, edge cases
- `design.md` — Technical approach, architecture decisions, file changes
- `tasks.md` — Ordered implementation tasks with estimates

### 3. Review
Human reviews artifacts. Edit freely — specs are living documents.

### 4. Build
```
> specclaw build add-dark-mode
```
- Spawns coding agents (Codex/Claude Code) per task
- Each agent gets fresh context: spec + design + relevant task
- Progress tracked in `status.md`
- Notifications on completion/failure

### 5. Verify
```
> specclaw verify add-dark-mode
```
- Validates implementation against spec requirements
- Runs tests if configured
- Reports gaps and issues

### 6. Archive
```
> specclaw archive add-dark-mode
```
- Moves to `.specclaw/changes/archive/`
- Updates `STATUS.md` dashboard

## Configuration

`.specclaw/config.yaml`:

```yaml
version: 1
project:
  name: "my-project"
  description: "Short description"

models:
  planning: "anthropic/claude-opus-4-6"    # For proposals, specs, design
  coding: "openai/codex-mini"              # For implementation
  review: "anthropic/claude-sonnet-4-5"    # For verification

git:
  strategy: "branch-per-change"  # or "direct"
  auto_commit: true
  commit_prefix: "specclaw"

notifications:
  channel: "discord"
  target: null  # Channel or user ID

automation:
  auto_mode: false
  cron: null  # e.g., "0 2 * * *" for nightly builds
  max_tasks_per_run: 5
```

## OpenClaw Integration

SpecClaw is built as an OpenClaw skill, leveraging:

- **`sessions_spawn`** — Isolated coding agents with fresh context per task
- **`message`** — Discord/Telegram notifications and approvals
- **`exec`** — Git operations, test runners, build tools
- **`memory_search`** — Cross-session continuity for long-running projects
- **Cron jobs** — Scheduled autonomous building

## Philosophy

- **Specs are contracts, not bureaucracy** — just enough structure to keep agents on track
- **Human in the loop** — approve proposals, review specs, but don't micromanage tasks
- **Fresh context per task** — each agent gets exactly what it needs, nothing more
- **Fluid, not rigid** — update any artifact anytime, no phase gates
- **Observable** — always know what's been built, what's pending, what failed

## License

MIT

## Contributing

PRs welcome! This is an early-stage project. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
