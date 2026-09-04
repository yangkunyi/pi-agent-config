---
name: implement-tickets
description: Dispatch ready tracker tickets to one-ticket children along the ready frontier.
disable-model-invocation: true
argument-hint: "[sequential|parallel]"
---

# Implement Tickets

You are the parent dispatcher. Spawn `general-purpose` children. Implementation, review, and commit live in the child via `/implement`.

Nested review inside the child needs `[subagents] max_depth` ≥ 2.

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

- **sequential** — 依次, sequential, or parallel was not said. One ready ticket. Shared cwd. Omit `isolation`.
- **parallel** — 并行. Every ready ticket. `isolation: "worktree"`.

Keep the ready-set and tracker writes in this parent session. Spawn only to run a child.

Loop across turns: spawn → yield → wake → record → spawn. Every spawn is `background: true`. Name the running tickets and end the turn. Do not `get_command_or_subagent_output` or `wait_commands_or_subagents` at spawn — those block the parent chat.

One writer per cwd. Sequential: the in-flight child holds the cwd. Parallel: worktrees isolate writers; wait for the wave's wake before merges or the next wave.

### On a wake

If this wave still has a running child, name who's left and end the turn.

**Completion.** For each finished child this wave:

- Success → treat it done, then resolve/close that ticket per `docs/agents/issue-tracker.md`. Leave parent issues open.
- Failure → mark failed; skip its dependents; continue with tickets that do not depend on it.

Then, if this wave was parallel, merge worktrees (§3) before spawning.

A child that stopped with a question: quote it to the user and end the turn. On the user's reply, `resume_from` that child with the reply as the prompt. The parent does not answer the child.

### Spawn

Only when no in-flight child (sequential) or wave (parallel) remains.

1. Compute the ready set. Empty with undone tickets → stop and name the blockers. Empty and all done → §4.
2. Sequential: lowest id. Parallel: every ready ticket.
3. `background: true`. Name the running tickets. End the turn.

Child prompt, first line is the slash command so `/implement` loads. Em dash (`—`):

```
/implement <id> — <title>

Fetch that ticket the way `docs/agents/issue-tracker.md` says. Several files share that id → match the title. Still ambiguous → stop and return the question. One ticket only.

Before the first edit, record `BASE=$(git rev-parse HEAD)`. Review fixed point is `$BASE`. Nested spawn fails with depth-limit → say so and skip those axes; do not invent a review.

If the ticket does not resolve, the ticket does not cover a product/architecture/scope choice, review blocks without a scope expansion, or you would touch another writer's files: stop and return the question in the final message.

Return: id/title, files, validation + exit codes, both review sections, commit hash or why not, risks, next step.
```

`<id>` is the tracker id as published (`01` locally, `#123` on GitHub). `<title>` is the ticket title.

`spawn_subagent`: `subagent_type: "general-purpose"`, `background: true`, `prompt` = that block, `description`: `[implement] <id> — <title>`. Sequential: omit `isolation`. Parallel: `isolation: "worktree"`.

Call `spawn_subagent` in the same response that first names that child.

## 3. Parallel merges

On a parallel wave's completion wake: each successful child's result includes a worktree path.

For each successful child, in id order:

```
git fetch <worktree_path> HEAD --no-tags
git merge --no-edit FETCH_HEAD
```

Merge conflict → stop and report. On a clean merge: `grok worktree rm --force <worktree_path>`. Skip failed children.

## 4. Report

Each ticket: done / failed / skipped-as-dependent. Sequential: the branch you were on. Parallel: which merges landed.
