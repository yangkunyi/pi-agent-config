---
name: implement-tickets
description: >-
  Dispatch tracker tickets to ticket-implementer along the ready frontier.
  Use when the user says 依次, 并行, implement tickets with subagents,
  to-tickets, or /implement-tickets.
argument-hint: "[sequential|parallel]"
---

# Implement Tickets

You are the parent dispatcher. Spawn `ticket-implementer` children. Implementation, review, and commit live in the child.

Stop if `ticket-implementer` is missing from `subagent({ action: "list" })`. Agent file: `~/.pi/agent/agents/ticket-implementer.md`.

## 1. Load tickets

Read `docs/agents/issue-tracker.md` and fetch tickets the way that file says.

Done when every open `ready-for-agent` ticket for the named or in-conversation feature has: tracker id, title, Blocked by, done-or-not.

If that file is missing, stop and tell the user to run `/setup-matt-pocock-skills`.
If no feature is identifiable, ask once.
If the list is empty, stop.

A ticket is **done** when the tracker already marks it resolved or closed, or a child for it succeeded this run.
A ticket is **ready** when it is not done and every Blocked-by ticket is done.

## 2. Dispatch

Pick **mode** once:

- **sequential** — 依次, sequential, or parallel was not said. One ready ticket. Shared cwd. Direct `subagent({ agent: "ticket-implementer", async: true, task })` child — not a `workflowScript`.
- **parallel** — 并行. Every ready ticket in one `workflowScript` + `runs.all`. `worktree: true` on each child.

Keep the ready-set and tracker writes in this parent session. Spawn only to run a child.

Loop across turns: spawn → yield → wake → record → spawn. Every spawn is `async: true`. Name the running tickets and end the turn. (`async: false` and `bg_wait` block the parent chat.)

One writer per cwd. Sequential: the in-flight child holds the cwd. Parallel: worktrees isolate writers; wait for the wave's wake before patches or the next wave.

### On a wake

**Completion.** For each finished child this wave:

- Success → treat it done, then resolve/close that ticket per `docs/agents/issue-tracker.md`. Leave parent issues open.
- Failure → mark failed; skip its dependents; continue with tickets that do not depend on it.

Then, if this wave was parallel, apply patches (§3) before spawning.

**`contact_supervisor`.** Quote the question to the user and end the turn. On the user's reply, forward that text with `subagent_supervisor`. The parent does not answer the child.

### Spawn

Only when no in-flight child (sequential) or wave (parallel) remains.

1. Compute the ready set. Empty with undone tickets → stop and name the blockers. Empty and all done → §4.
2. Sequential: lowest id, direct child. Parallel: every ready ticket, one workflow.
3. `async: true`. Name the running tickets. End the turn.

Child task, one line, em dash (`—`):

```
/implement <id> — <title>
```

`<id>` is the tracker id as published (`01` locally, `#123` on GitHub). `<title>` is the ticket title.

Sequential:

```js
subagent({
  async: true,
  agent: "ticket-implementer",
  task: "/implement 01 — title"
})
```

Parallel. Stable key per ticket (`t01`, `t03`). Ready tickets only:

```js
subagent({
  async: true,
  workflowScript: `
    const results = await runs.all([
      { key: "t01", agent: "ticket-implementer", worktree: true, task: "/implement 01 — title" },
      { key: "t03", agent: "ticket-implementer", worktree: true, task: "/implement 03 — title" }
    ]);
    return results.map(r => ({ key: r.key, ok: r.ok, output: r.output, artifactPaths: r.artifactPaths }));
  `
})
```

## 3. Parallel patches

On a parallel wave's completion wake: managed worktrees capture a patch and a handoff, then clean themselves.

For each successful child, in id order, apply that child's captured patch from `artifactPaths`. Conflict → stop and report. Skip failed children.

## 4. Report

Each ticket: done / failed / skipped-as-dependent. Sequential: the branch you were on. Parallel: which patches landed.
