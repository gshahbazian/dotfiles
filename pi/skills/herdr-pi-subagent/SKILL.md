---
name: herdr-pi-subagent
description: "Spin up 1-5 parallel read-only pi sub-agents in Herdr for background investigation. Use when a task benefits from concurrent exploration, research, or verification that should not modify the workspace. Requires HERDR_ENV=1."
---

# Herdr Pi Sub-agents

Use Herdr to run short-lived parallel **pi** workers for background investigation. Keep synthesis, decisions, and all writes in the main agent.

## When to use

- The work splits cleanly into 1-5 independent read-only investigations
- Examples: explore different packages, gather evidence from logs, compare APIs, audit call sites, verify hypotheses

Do **not** use this for work that must edit files, create files, commit, push, or otherwise mutate the repo. Do that yourself.

## Preconditions

```bash
test "${HERDR_ENV:-}" = 1
```

If that fails, say you are not inside Herdr and continue without sub-agents.

For full Herdr topology/CLI details, load the `herdr` skill. This skill only covers the sub-agent pattern.

## Worker constraints

Every sub-agent must be:

- **kind:** `pi`
- **model:** `openai-codex/gpt-5.6-terra` (include the provider prefix)
- **thinking:** `low` (fast/cheap workers; do not inherit the caller's high thinking default)
- **tools:** no write/edit tools
- **behavior:** read-only only

Start workers with tool denylist, model, and thinking level pinned:

```bash
herdr agent start <name> --kind pi --pane <pane-id> -- \
  --model openai-codex/gpt-5.6-terra \
  --thinking low \
  --exclude-tools write,edit
```

Equivalent model shorthand also works: `--model openai-codex/gpt-5.6-terra:low`. Prefer the explicit `--thinking low` flag so the level is obvious in logs.

Also put these rules in every worker prompt (workers are leaves — never coordinators):

1. Never create, edit, delete, move, or overwrite files.
2. Never commit, push, install packages, migrate data, or change system state.
3. Only use read-only tools and read-only shell commands (`rg`, `git show`, `git log`, `git diff`, `ls`, `cat`/`read`, tests that do not write, etc.).
4. Never spawn sub-agents or parallel workers. Never load `herdr-pi-subagent` or `herdr`. Never run `herdr agent start`, `herdr tab create`, `herdr pane split`, or any Herdr command that creates layout or agents.
5. Do all investigation yourself. If scope is too large, report what you covered and what remains — do not delegate.
6. If a step seems to require mutation, stop and report that instead of doing it.
7. Return a concise evidence-backed report: findings, file paths, and residual uncertainty. No drive-by refactors or suggested patches as applied changes.

## Workflow

### 1. Split the work

Break the background task into **1-5** independent workstreams. Prefer fewer sharp workers over many overlapping ones. Give each worker:

- a unique name matching `[a-z][a-z0-9_-]{0,31}`
- a single clear question or scope
- only the context it needs

### 2. Create a dedicated sub-agent tab

**Do not split panes in the caller's tab.** Sub-agents take over the user's layout when created as siblings. Always put workers in a separate tab in the current workspace.

Create the tab with label `pi herdr subagents`, preserve cwd, and do not steal focus:

```bash
herdr tab create --workspace "$HERDR_WORKSPACE_ID" \
  --cwd "$PWD" \
  --label "pi herdr subagents" \
  --no-focus
```

Read from the JSON response:

- tab id: `.result.tab.tab_id`
- first pane id: `.result.root_pane.pane_id` (or equivalent root pane field)

Stay on the calling tab/pane. Do not `tab focus` the sub-agent tab unless the user asks to look at it.

If a tab labeled `pi herdr subagents` already exists in this workspace and is idle/reusable, you may reuse it instead of creating another. Prefer one sub-agent tab per fan-out.

### 3. Create worker panes inside that tab

Use the new tab's root pane for the first worker. For each additional worker, split panes **inside the sub-agent tab only** (never the caller's tab):

```bash
herdr pane split --pane <subagent-pane-id> --direction right --cwd "$PWD" --no-focus
```

Inspect geometry with `herdr pane layout --pane <subagent-pane-id>` if needed. Split wide panes right and tall/narrow panes down. Avoid repeated same-direction splits that make panes unusable.

Read each new pane ID from `.result.pane.pane_id`.

### 4. Start one pi worker per pane

```bash
herdr agent start scout-api --kind pi --pane <pane-id> -- \
  --model openai-codex/gpt-5.6-terra \
  --thinking low \
  --exclude-tools write,edit
```

`agent start` returns only after the worker is ready for input (default 30s timeout).

After start, quickly confirm the footer/model line shows `(openai-codex) gpt-5.6-terra` with `low` thinking (or equivalent) and there is no auth/API key error before prompting.

### 5. Prompt all workers

`herdr agent prompt` takes the text **before** flags:

```bash
herdr agent prompt <target> <text> [--wait] [--until STATUS]... [--timeout MS]
```

Submit work with `--wait`:

```bash
herdr agent prompt scout-api "$(cat <<'EOF'
You are a leaf read-only investigation sub-agent (not a coordinator).

Hard rules:
- Never create or modify files.
- Never run mutating commands.
- Use only read-only tools/commands.
- Never spawn sub-agents or parallel workers.
- Never load herdr / herdr-pi-subagent.
- Never run herdr agent/tab/pane create/start/split commands.
- If scope is too large, report partial findings + remaining work. Do not delegate.
- If mutation seems required, stop and report that.

Task:
<one concrete investigation>

Report format:
- Summary (3-6 bullets)
- Evidence (paths, symbols, commands observed)
- Open questions / unknowns
EOF
)" --wait --timeout 300000
```

Fan out prompts to all workers before spending a long time on any one result.

### 6. Collect results

For each worker:

```bash
herdr agent get <name>
herdr agent read <name> --source recent-unwrapped --lines 120
```

If a wait fails or the agent is `blocked`, inspect `get`/`read` before sending more input.

If a completed response is truncated because the worker is on the alternate screen, as a fallback ask it to write the full Markdown report under `/tmp` and reply with only that path, then read the file yourself. Do not request file output in the initial prompt.

### 7. Synthesize yourself

Merge worker findings in the main agent. Resolve conflicts, decide next actions, and perform any writes or mutations yourself.

### 8. Clean up the sub-agent tab

After collection, shut down workers and remove the tab you created so it does not clutter the workspace:

```bash
# optional: exit agents first if still live
herdr tab close <subagent-tab-id>
```

Do not close the caller's tab or any tab/pane you did not create. If the user asks to inspect workers, leave the tab open.

## Coordination rules

- Use 1-5 workers max per fan-out.
- Always isolate workers in a tab labeled `pi herdr subagents`; never split the caller's tab for sub-agents.
- Use `--no-focus` on tab create and pane splits so background workers do not steal the user's UI focus.
- Keep user focus on the calling pane/tab throughout.
- Target workers by unique name or explicit pane ID; do not rely on another client's focused pane.
- Parse tab/pane/agent IDs from JSON responses.
- Do not close panes/tabs/workspaces you did not create unless the user asks.
- Do not nest another Herdr fan-out inside a worker. Every worker prompt must include the leaf rules above so workers never spawn agents themselves.
- Prefer closing the sub-agent tab after collection unless the user wants to inspect it.
