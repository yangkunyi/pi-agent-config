---
name: orchestrator
description: >
  Drive the Orchestrator CLI on a Target git repo: detach-drain implementation
  Tickets, inspect a Run, retry a FAILED ticket. Use when the user says run,
  start, or drain orchestrator; inspect the run; what's running; or retry FAILED.
argument-hint: "<target>"
---

# Orchestrator

You operate the scheduler. Pi inside it implements Tickets. Merge stays on local Main.

Commands (`orchestrator --help` for flags):

```
orchestrator <target> --detach
orchestrator inspect <target> [id]
```

Binary: `orchestrator` on PATH (`~/.local/bin/orchestrator`). `--run-id` is internal to the detached child; operator commands never include it.

## Status-only

User asked what is running / inspect / check a Run: `orchestrator inspect <target> [id]`. Print it. Stop.

No id: live Run if one exists, else the Run list. With id: that Run (pid, DAG snapshot, last events).

## Drain

### 1. Resolve Target

Target = the git repo whose `.scratch/` holds the Tickets, as an absolute path.

Use the path the user named. If they named none: cwd when it has `.scratch/*/issues/*.md`, else ask. Done when the path exists and is a git repo.

### 2. Preflight

Run all of these. Stop and quote the blocker; do not start.

- `command -v orchestrator` — missing: try `~/.local/bin/orchestrator` or say it is not on PATH.
- `git -C <target> status --porcelain` — any output: Target Main is dirty. Tickets and gitignore must already be committed. Orchestrator refuses a dirty Main.
- `orchestrator inspect <target>` — a live Run: inspect that Run. Do not start a second. One live Run per Target.
- Ticket files at `<target>/.scratch/*/issues/<NN>-<slug>.md` with no wayfinder `Type:` (`research` / `prototype` / `grilling` / `task`). Skip those. A Ticket is startable when Status is not `MERGED`/`FAILED`/`RUNNING`/`MERGING`/`CONFLICT`/`RESOLVING` and every `Blocked by` id is `MERGED`. None startable: say so (all MERGED, or still BLOCKED, or none published — `/to-tickets` publishes).
- Ticket files with Status `RUNNING`/`MERGING`/`CONFLICT`/`RESOLVING` and no live Run: say so. The next start stamps those FAILED. Wait if the user may want the leftover worktree first.

Done when Main is clean, no live Run, and at least one Ticket is startable.

### 3. Start

```
orchestrator <target> --detach
```

Add `--model` / `--thinking-level` / `--concurrency` only when the user named them. Otherwise Target `.scratch/orchestrator.yaml` (keys `model`, `thinkingLevel`, `concurrency`, `httpProxy`) or binary defaults. The detached child is started with `NODE_USE_ENV_PROXY=1` so Pi `fetch` uses `HTTP_PROXY`. YAML `httpProxy` (clash on this machine: `http://127.0.0.1:23379`) is copied into that env.

Done when stdout is `run <id> detached`. Keep that id.

### 4. Watch

Do not implement Tickets. Do not open worktrees to code. Watch that id until it has exited.

Silent until terminal. Monitor (no stdout except the last line):

```bash
T=<target> ID=<id>
while :; do
  out=$(orchestrator inspect "$T" "$ID") || { echo FAILED; exit 1; }
  case "$out" in
    *"exited  exit 0"*) echo DONE; exit 0 ;;
    *"exited  exit "*) echo FAILED; exit 1 ;;
    *"stale  pid"*) echo FAILED; exit 1 ;;
  esac
  sleep 30
done
```

User asks status while it runs: `orchestrator inspect <target> <id>` once, then keep the monitor.

Done when inspect for that id shows `exited` (or `stale`).

### 5. Report

`orchestrator inspect <target> <id>`. Then say:

- Run id, exit code
- Each Ticket id and Status from the DAG snapshot
- Every `FAILED` Ticket: id, the event line with the reason, leftover worktree `<target>/worktrees/<feature>-<NN>-<slug>`

A FAILED Ticket only blocks Tickets that list it in `Blocked by`. Independent Tickets may already be MERGED. Exit 0 can still include FAILED Tickets.

Done when that list is in the reply. Do not start another Run. Do not rewrite Status.

## Retry FAILED

Only when the user names the Ticket.

1. Main clean.
2. On Main, set that file's `Status:` to `READY` and commit.
3. Drain (new Run). Orchestrator recreates the worktree from current Main HEAD.

## Kill a Run

Only when the user asks. Killing leaves Ticket Status in-flight; the next start stamps those FAILED.

## Words

| Word | Means |
| --- | --- |
| Target | Git repo being scheduled. Path argument. |
| Main | Target integration branch. MERGED lands here. |
| Ticket | `.scratch/<feature>/issues/<NN>-<slug>.md`. Id `<feature>/<NN>`. |
| Run | One Orchestrator process. Records: Target `.scratch/orchestrator/runs/<id>/` (gitignored). |
| Status | Lifecycle on the Ticket file. `/to-tickets` writes initial `READY`/`BLOCKED`. Orchestrator writes the rest. `/implement` leaves it unchanged. |

Ticket layout and Status table: `setup-matt-pocock-skills/issue-tracker-local.md`.
