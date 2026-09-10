---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use /code-review to review the work.

Commit your work to the current branch.

Leave the ticket file's `Status:` line unchanged (`BLOCKED` / `READY` / `RUNNING` / `MERGING` / `CONFLICT` / `RESOLVING` / `MERGED` / `FAILED`). Those values are owned by `/to-tickets` and the Orchestrator, not by implement.
