---
name: implement-tickets
description: >-
  Dispatch each tracker ticket to the `ticket-implementer` subagent with
  `/implement <NN> — <title>`. Parent reads `docs/agents/issue-tracker.md`,
  honors Blocked by, and walks the ready frontier sequentially (依次) or
  fans out unblocked tickets in worktrees (并行). Use when the user says
  依次/并行实现 to-tickets, implement tickets with subagents, or runs
  `/implement-tickets`.
argument-hint: "[sequential|parallel]"
---

# Implement Tickets

You are the parent. List tickets and spawn `ticket-implementer` children. Do not implement, review, or commit. Review happens inside `ticket-implementer`.

If `ticket-implementer` is missing from `subagent({ action: "list" })`, stop. It lives at `~/.pi/agent/agents/ticket-implementer.md`.

## Mode

- **sequential** — 依次 / sequential / one at a time, or parallel was not said. One ready ticket at a time. Shared cwd. No `worktree`.
- **parallel** — 并行 / parallel / fan out. Every currently ready ticket at once. `worktree: true` on each child.

## Async (hard)

Every spawn is `async: true`. After launch, say which tickets are running and **end the turn**. Main chat stays free. Pi wakes this parent on completion; continue the loop on that wake.

`async: false` and `bg_wait` block the parent chat. Never use them here.

One writer per cwd. Sequential: do not spawn the next ticket, and do not edit that cwd, while a child is in flight. Parallel: children are isolated by `worktree`; still wait for the wave's wake before applying patches or starting the next wave.

Reply to `contact_supervisor` with `subagent_supervisor` if a child asks. That is a wake, not a reason to block.

## 1. Load tickets

Read `docs/agents/issue-tracker.md` and fetch tickets the way that file says.

Done when every open `ready-for-agent` ticket for the named or in-conversation feature has: tracker id, title, Blocked by, done-or-not.

If that file is missing, stop and tell the user to run `/setup-matt-pocock-skills`.
If no feature is identifiable, ask once.
If the list is empty, stop.

A ticket is **done** when the tracker already marks it resolved or closed, or a child for it succeeded this run.
A ticket is **ready** when it is not done and every Blocked-by ticket is done.

## 2. Dispatch (this turn)

The workflow sandbox has no filesystem. Keep the ready-set and tracker writes in this parent session. Spawn only to run a child. The loop spans turns: launch → yield → wake → record → launch next.

**On a completion wake**, for each finished child this wave:

- Success → treat it done, then record completion on that ticket using the resolve/close path in `docs/agents/issue-tracker.md`. Do not close a parent issue.
- Failure → mark failed; do not spawn its dependents; continue with tickets that do not depend on it.

Then, if this was a parallel wave, do §3 before spawning again.

**Then spawn** only when no in-flight child (sequential) or wave (parallel) remains:

1. Compute the ready set. Empty while undone tickets remain → stop and name the blockers. Empty and all done → §4.
2. Sequential: spawn the lowest id. Parallel: spawn every ready ticket in one workflow.
3. `async: true`. Name the running tickets. End the turn.

**Child task is exactly one line, no other text:**

```
/implement <id> — <title>
```

`<id>` is the tracker id as published (`01` locally, `#123` on GitHub). `<title>` is the ticket title. The dash is an em dash (`—`).

Sequential, one child:

```js
subagent({
  async: true,
  workflowScript: `return runs.run("t01", { agent: "ticket-implementer", task: "/implement 01 — title" })`
})
```

Use a stable key per ticket (`t01`, `t02`).

Parallel wave, isolated writers:

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

Only include tickets that are ready in this wave.

## 3. After a parallel wave

On the wave's wake: managed worktrees capture a patch and a handoff, then clean themselves. Do not `git worktree remove` by hand.

For each successful child, in id order, apply that child's captured patch from `artifactPaths`. Conflict → stop and report. Skip failed children; do not apply their patches.

## 4. Report

Each ticket: done / failed / skipped-as-dependent. Sequential: the branch you were on. Parallel: which patches landed.
