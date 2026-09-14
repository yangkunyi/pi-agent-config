# pi's configuration is local; grok's guidance stays linked

**Status:** Accepted 2026-09-14

## Context

`install.sh` linked `skills`, `agents`, `AGENTS.md`, `settings.json`, `optimizer.json` and `models.json`
from this repository into `~/.pi/agent/`. Two of those links had already cost something: `models.json`
belongs to cc-switch ("Pi owns the current/default provider; CC Switch only manages explicit
`models.json` entries"), and the `skills` link is the layout ADR-0001 removes.

With skills moving to a shared root and cc-switch covering providers, MCP servers and prompts, the
question was what this repository still manages.

## Decision

- **pi's configuration is local.** `agents/`, `AGENTS.md`, `settings.json`, `optimizer.json` and
  `models.json` are real files under `~/.pi/agent/`; this repository keeps the last snapshot of each in
  git and does not link them. `install.sh` is deleted — its only remaining job would have been to
  re-create the `skills` symlink and shadow the shared root.
- **grok keeps its links.** `install-grok.sh` links `agents` and `AGENTS.md` (grok's spawn API differs
  from pi's, so those two stay separate trees) and points `~/.grok/skills` at the shared root.
  `config.toml` stays a machine-local file on purpose: grok rewrites it (`max_depth`, model backend
  switching), so it is a template here, never a link.
- **`auth.json` is always local**, on both sides.

## Consequences

- pi's configuration has no version history and no cross-machine channel beyond this snapshot. That is
  the accepted cost of the decision; the files are small and rarely change.
- What each channel carries is now nameable: **git** carries sources (skills, pack, grok guidance),
  **cc-switch + WebDAV** carries providers/MCP/prompts and the live skills root, and **the machine**
  carries auth, sessions, and pi's own settings.
- Adding a machine is one clone, one `install-grok.sh`, and one cc-switch login — no pi-side linking
  step remains.
