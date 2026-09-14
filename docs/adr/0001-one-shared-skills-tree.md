# One shared skills tree

**Status:** Accepted 2026-09-14

## Context

Three trees carried the same skills, and each had a different writer:

- `~/.cc-switch/skills/` — cc-switch's own source of truth (32 members, most of them the bytes of
  2026-08-17).
- `pi-agent-config/skills/` — the config repository's copy, reached on every machine through
  `~/.pi/agent/skills` → `pi-agent-config/skills`. cc-switch's sync wrote *through* that symlink, so
  the repository was a deployment target it did not know about.
- `~/.agents/skills/` — the shared Agent Skills root, where the lark/archon CLI installers place
  their 29 skills and which `~/.claude/skills`, `~/.hermes/skills` and `~/.openclaw/skills` already
  linked into.

The measurement that forced a decision: `cc-switch skills sync` would have overwritten the 2026-09-12
skill work with the August bytes (`ask-matt` 030108f8 → eebeff56, `to-tickets` 3ffa7786 → 522d81a9).
One file, two writers, neither acknowledged.

## Decision

Skills have exactly three roles, and one holder each:

- **The live tree is `~/.agents/skills/`.** pi reads it natively (its `docs/skills.md` lists it beside
  `~/.pi/agent/skills/`), `~/.grok/skills` is a symlink to it, and every other agent's directory
  carries links into it.
- **git holds the sources and the snapshot.** The nineteen global skills are edited in this
  repository's `skills/`; the seven beads-backed members are edited in `beads-matt-dag/skills/`; the
  lark/archon set is owned by its own installer and is deliberately not stored here. Installing means
  copying the member into the root, and the copy is the only write that reaches it.
- **cc-switch is the channel.** Its storage location is `unified` (the same root), its sync method is
  `symlink`, and the whole root rides WebDAV as `skills.zip` (measured 2,003,922 bytes at
  `cc-switch-sync/v2/db-v6/default/skills.zip`). Its per-app matrix no longer decides what pi sees —
  a root is a root — so pi's row is off for every skill, and `~/.pi/agent/skills` is deleted so
  nothing re-creates it.

## Consequences

- A skill name is unique machine-wide, so the collision rule pi documents (first found wins) can only
  ever fire against a project-local copy.
- `caveman` became visible to pi by arriving in the root; `ponytail` ×6 was uninstalled instead.
  Anything cc-switch installs lands where pi can see it — that is the trade the single tree buys.
- The root grows with its installers. `cc-switch skills import-from-apps <name>` (a bare member name,
  not a path: an absolute path is rejected as a possible traversal) is how a member from an app
  directory becomes a record; without that record the WebDAV snapshot refuses to replace the root.
- **A managed app directory must not be a symlink into a repository.** cc-switch's `sync` cleans up
  deployments for apps where a skill is disabled; while `~/.pi/agent/skills` was a symlink into this
  repository, that cleanup deleted the repository's tracked working tree (105 files, restored from git
  the same hour, nothing lost). An external manager gets a directory it owns.

## Rejected

- **Let cc-switch manage the repository** (its Pi row as the deployment target): it makes a git working
  tree the live state for every skill, and every `git checkout` becomes a skills change.
- **Keep three trees and a diff check**: the diff can see drift, never stop it, and it cannot see a
  writer it does not know about.
- **Let pi read only its own directory**: that is the layout that produced the two-writers problem.
