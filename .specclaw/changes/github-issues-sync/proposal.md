# Proposal: GitHub Issues Sync

**Created:** 2026-03-28
**Status:** 🟡 Draft

## Problem

SpecClaw tracks everything locally in markdown files — great for the agent, invisible to the team. When a repo is connected to GitHub:

- Team members can't see what's being planned/built without reading `.specclaw/` files
- No way to comment on tasks or proposals from GitHub
- Can't use GitHub project boards for visibility
- No issue references in commits (no auto-close on merge)
- PR reviewers have no context about which spec/task a change belongs to

## Proposed Solution

When `github.sync: true` is configured, SpecClaw syncs its workflow to GitHub Issues:

### What gets synced:

| SpecClaw Artifact | GitHub Issue | Labels |
|---|---|---|
| Proposal | Issue with `specclaw:proposal` label | + change name |
| Each task in tasks.md | Issue with `specclaw:task` label | + wave number, estimate |
| Build errors | Comment on the task issue | — |
| Learnings | Comment on the proposal issue | — |
| Verification results | Comment on the proposal issue | — |

### Lifecycle mapping:

```
specclaw propose  →  Creates proposal issue (open)
specclaw plan     →  Creates task issues, links to proposal
specclaw build    →  
  task starts     →  Assigns "in progress" label
  task completes  →  Closes issue, references commit
  task fails      →  Adds "failed" label + error comment
specclaw verify   →  Adds verification comment to proposal
specclaw archive  →  Closes proposal issue with "completed" label
```

### Issue body includes:

**Proposal issue:**
```markdown
## Proposal: Add dark mode

**Change:** add-dark-mode
**Status:** 🟢 Approved

<proposal.md content>

---
*Managed by [SpecClaw](https://github.com/chanbistec/specclaw) — do not edit directly*
```

**Task issue:**
```markdown
## Task T3 — Create toggle component

**Change:** add-dark-mode
**Wave:** 2
**Depends:** T1, T2
**Estimate:** small
**Files:** src/components/ThemeToggle.tsx

<task notes>

---
*Part of #42 (proposal). Managed by SpecClaw.*
```

### Bidirectional (future):
- Comments on GitHub issues could feed back as learnings
- Closing a task issue manually marks it complete in tasks.md
- (Phase 2 — keep out of scope for now)

## Configuration

```yaml
github:
  sync: true                    # Enable GitHub sync
  repo: "owner/repo"            # Auto-detect from git remote if empty
  labels_prefix: "specclaw"     # Prefix for auto-created labels
  create_milestone: true        # Create a milestone per change
  link_commits: true            # Add issue refs to commit messages
```

## Implementation Approach

A single script `scripts/gh-sync.sh` that uses the `gh` CLI (GitHub CLI) — already widely available and handles auth. Subcommands:

- `gh-sync.sh setup` — Create labels, verify auth
- `gh-sync.sh propose <change>` — Create proposal issue
- `gh-sync.sh plan <change>` — Create task issues, link to proposal
- `gh-sync.sh update <change> <task_id> <status>` — Update task issue (label, close, comment)
- `gh-sync.sh comment <change> <issue_type> "<text>"` — Add comment to proposal/task issue
- `gh-sync.sh archive <change>` — Close all issues for change

Issue numbers stored in `.specclaw/changes/<change>/.github-issues.json`:
```json
{
  "proposal": 42,
  "tasks": {
    "T1": 43,
    "T2": 44,
    "T3": 45
  },
  "milestone": 3
}
```

## Scope

### In Scope
- `gh-sync.sh` script with all subcommands
- Label auto-creation (specclaw:proposal, specclaw:task, specclaw:wave-1, etc.)
- Issue creation for proposals and tasks
- Status updates (labels + close/reopen)
- Error and learning comments on issues
- Commit message issue references (`#43`)
- Issue number tracking in `.github-issues.json`
- Config additions to config.yaml
- SKILL.md integration (sync calls in propose/plan/build/verify/archive flows)

### Out of Scope
- GitHub Projects board integration (future)
- Bidirectional sync (GitHub → SpecClaw) (future)
- PR auto-creation (future)
- Non-GitHub providers (GitLab, Bitbucket) (future)

## Impact

- **Files affected:** ~6 (new script, config template, SKILL.md updates, issue tracking file)
- **Complexity:** medium-large
- **Risk:** medium — depends on `gh` CLI being available and authenticated

## Open Questions

1. Should we require `gh` CLI or also support raw GitHub API via curl + token?
2. Create a milestone per change, or just use labels for grouping?
3. Should `.github-issues.json` be committed or gitignored?
4. When a task is retried, reopen the issue or create a new one?

---

**To proceed:** Review this proposal and approve to begin planning.
