# Packs install by symlink

**Status:** Accepted 2026-09-14

## Context

The Archon pack for the beads flow (`beads-dag`) lived in the project repository that produced it
(`beads-matt-dag`) and was installed by copying the folder into `~/.archon/workflows/beads-dag`, with
`diff -rq` as the only proof that the installed copy was the source. Two texts stated it as a rule
("copy, not a symlink"), and `ticket-dag` was installed the same way from `/data3/yky/workflow`.

That convention had three costs: installing was a manual step that had to be remembered after every
pack change; the identity of the installed version was unprovable except by diffing; and the project
repository had no remote, so no other machine could obtain the pack from git at all.

Measured before deciding: `archon workflow list` discovers a pack through a symlink (both
`beads-dag-drain` and `beads-dag-execute` listed), and Archon's own guard against two runs in one home
does not care how the workflow directory was reached.

## Decision

Every pack has exactly one git home, and a machine's install is a symlink to the pack folder inside a
checkout:

```
ln -sfn "/path/to/checkout/.archon/workflows/<pack>" ~/.archon/workflows/<pack>
```

- `beads-dag`'s home is `beads-matt-dag`, now published privately as
  `git@github.com:yangkunyi/beads-matt-dag.git`. Updating an install is `git pull`.
- `ticket-dag` is retired: its install is removed and `/data3/yky/workflow` stays as the artifact.
- The two texts that stated the copy rule (the pack's `README.md` and the `beads-dag-drain.yaml`
  description) state the link instead.

## Consequences

- The installed version *is* the working tree: an edit in progress is what a run would read. The
  protection is the pack's own gate suite, which runs from the repository before a change is taken as
  done — not a second copy.
- A machine without a checkout cannot have the pack (it needs git access and, for a private home, a
  key). That is the same requirement the config repository already has.
- The copy-then-diff step disappears, including the failure it used to catch by hand: drift between
  installed and source is now impossible by construction.
- The run-time path is the one thing not exercised by the measurement above: discovery was tested, a
  full drain from a symlinked install was not (accepted 2026-09-14, per the operator's decision not to
  stage one). The first real drain is the test, and the fallback if it fails is a copy.
