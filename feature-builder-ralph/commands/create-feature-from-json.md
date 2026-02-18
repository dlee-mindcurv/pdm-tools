---
name: create-feature-from-json
allowed-tools: Read, Write, Edit, Exit, Grep, Glob, Task, Bash
description: Create Feature from user stories
argument-hint: [path to feature JSON file]
---

The first argument is the path to the feature JSON file (e.g., `features/pink-footer/prd.json`). All references below use `$FEATURE_FILE` to mean that provided path.

Read `appDir` and `branchName` from the feature file in a single call: `jq -r '[.appDir, .branchName] | @tsv' $FEATURE_FILE`. All references below use `$APP_DIR` for the `appDir` value (e.g., `.`) and `$BRANCH_NAME` for the `branchName` value.

## Worktree detection

Derive the feature name from `$FEATURE_FILE` (e.g., for `features/pink-footer/prd.json`, the feature name is `pink-footer`). Check if a worktree exists at `.worktrees/<feature-name>/`. If it does:
- Override `$APP_DIR` to `.worktrees/<feature-name>/<original-appDir>` (e.g., `.worktrees/pink-footer/app`)
- Set `$LEARNINGS_FILE` to `.worktrees/<feature-name>/features/learnings.md`

If no worktree exists (backward compatibility):
- `$APP_DIR` stays as the original value
- Set `$LEARNINGS_FILE` to `features/learnings.md`

## Log initialization and status check

Derive the feature directory from `$FEATURE_FILE` (e.g., `features/pink-footer/`). Set `$LOG_FILE` to `<feature-dir>/agent-log.json`.

Run a single consolidated status query:
```bash
jq '{
  stories: [.userStories[] | {id, passes, jobs: [.jobs[] | {name, status, dependsOn}]}],
  freshStart: ([.userStories[0].jobs[].status] | all(. == "pending")),
  firstIncomplete: [.userStories[] | select(.passes == false)][0]
}' $FEATURE_FILE
```

If `freshStart` is `true` (or if `$LOG_FILE` doesn't exist), create/reset `$LOG_FILE` to `[]`.

## Skill resolution

Read the `## Agent Skills` table from `CLAUDE.md` (or `.worktrees/<feature-name>/CLAUDE.md` if a worktree is in use). If the section doesn't exist, skip skill loading entirely (backward compatible).

For each agent type that has skills listed in the table:

1. Parse each skill entry: if it ends with `:full`, strip the suffix and set target to `AGENTS.md`; otherwise set target to `SKILL.md`
2. Resolve the file path in order:
   - `$HOME/.agents/skills/<skill-name>/<target>` (primary)
   - `$HOME/.claude/skills/<skill-name>/<target>` (fallback location 1)
   - `.agents/skills/<skill-name>/<target>` (fallback location 2)
   - `.claude/skills/<skill-name>/<target>` (fallback location 3)
   - If the target file doesn't exist at either location, try the other file (AGENTS.md → SKILL.md or vice versa) at both locations
3. Read the resolved file content
4. If not found at any location, log a warning but continue without that skill

Store resolved skills as a mapping of agent type → list of `{name, content}` pairs for use during dispatch.

## Dispatch

> **CRITICAL**: The orchestrator is the SOLE authority over job dispatch and status management.
> - NEVER manually edit job statuses in `$FEATURE_FILE` — only dispatched sub-agents may update their own job status
> - NEVER skip the dispatch loop by running agents outside this orchestrator
> - NEVER output the completion promise unless all stories have `passes: true`
> - Each agent MUST receive `$FEATURE_FILE`, `$APP_DIR`, and `$LEARNINGS_FILE` in its prompt so it can update its own status

Use the `stories` array from the consolidated query to check status.

1. If all userStories have `passes: true`, proceed to the **Feature completion** section below
2. Use `firstIncomplete` from the consolidated query as the current story to process
3. Find runnable jobs: A job is runnable when its own status is `"pending"` AND (`dependsOn` is null OR the dependency job's status is `"done"`), **except**: the `playwright` job is runnable when its own status is `"pending"` AND the `build` job's status is `"generated"`. All other jobs continue to gate on `"done"`.
4. Before dispatching agents, capture: `BATCH_START=$(date -u +%Y-%m-%dT%H:%M:%SZ)`. Then invoke each runnable job's agent in parallel via Task tool using the `firstIncomplete` story data already loaded. **Include all three paths in each agent's prompt:**
   - `$FEATURE_FILE` — the feature file path in the main directory (for status updates)
   - `$APP_DIR` — the app directory, which may be in a worktree (for code changes)
   - `$LEARNINGS_FILE` — the learnings file path, which may be in a worktree (for reading/writing learnings)
   - Skill content: include any `<skill>` blocks resolved for this agent type from the skill resolution step. Wrap each skill's content as: `<skill name="skill-name">\n[file content]\n</skill>`
   - For each agent that receives skills, add to its prompt: "In your JSON response, include a `skillsConsulted` array listing the names of skills you actively referenced during implementation."

   After all Task calls return, capture: `BATCH_END=$(date -u +%Y-%m-%dT%H:%M:%SZ)`.

## Write log entries

For each agent that ran, parse its JSON response. Construct a log entry object with:
- `storyId`, `job`, `agent` from the dispatch context
- `status`, `iterations`, `error` from the agent's JSON response
- `startedAt`/`finishedAt` from the agent's JSON response; if either is `null`, substitute `$BATCH_START`/`$BATCH_END` respectively
- `skillsProvided`: array of skill names that were injected into this agent's prompt (from the skill resolution step; `[]` if none)
- `skillsConsulted`: array from the agent's JSON response (default `[]` if absent or agent doesn't report it)

Read `$LOG_FILE`, append the new entries to the array, and write it back.

The agent-to-job mapping is: `build-user-story` → `build`, `run-playwright` → `playwright`, `run-lint` → `lint`, `run-typecheck` → `typecheck`, `write-tests` → `test`.

## Finalize story

After all jobs for the story are `done`, set `passes: true` in `$FEATURE_FILE`.

## Feature completion

When all userStories have `passes: true`, perform the following steps before outputting the completion promise.

### Pre-completion verification

Run a single consolidated completion query:
```bash
jq '{
  allPass: ([.userStories[].passes] | all),
  description: .description,
  storyTitles: [.userStories[].title],
  incompleteCount: ([.userStories[] | select(.passes != true)] | length)
}' $FEATURE_FILE
```

If `incompleteCount` is NOT `0`, do NOT proceed. Instead, return to "Log initialization and status check" to process remaining stories.

### Write completion marker

Immediately after confirming `incompleteCount` is `0`, write a completion marker file:

```bash
echo "done" > .claude/ralph-completed
```

This marker is written before learnings/git operations so it persists even if context compression later causes Claude to skip the `rm` and `<promise>` output steps.

### Learnings integration (only if worktree is in use)

If a worktree is in use (i.e., `.worktrees/<feature-name>/` exists):

1. Read `$LEARNINGS_FILE` (the worktree's `features/learnings.md`)
2. If it contains findings beyond the initial template (i.e., not just "(none yet)"), read the worktree's `CLAUDE.md` at `.worktrees/<feature-name>/CLAUDE.md` and append the learnings to a `## Learnings` section at the bottom. If the section already exists, merge the new findings into it. Write the updated file back.

### Git operations (only if worktree is in use)

If a worktree is in use, use the `description` and `storyTitles` from the completion query above:

1. Stage app changes: `git -C .worktrees/<feature-name> add <original-appDir>/`
2. Stage CLAUDE.md if it was modified: `git -C .worktrees/<feature-name> add CLAUDE.md`
3. Check if there are staged changes: `git -C .worktrees/<feature-name> diff --cached --quiet`. If there are **no** staged changes, skip steps 4-6 (nothing to commit/push/PR) and proceed to "Stop the Ralph loop".
4. Commit: `git -C .worktrees/<feature-name> commit -m "feat(<feature-name>): <description>"`
5. Push: `git -C .worktrees/<feature-name> push -u origin $BRANCH_NAME`
6. Create PR (only if one doesn't already exist for `$BRANCH_NAME`):
   ```
   gh pr create --head $BRANCH_NAME --base main \
     --title "feat: <description>" \
     --body "<PR body>"
   ```
   The PR body should include:
   - Feature description
   - List of implemented user stories with their titles
   - Note: "Auto-generated by Ralph"
7. Log the PR URL in the output

### Stop the Ralph loop

Delete the Ralph loop state file so the stop hook allows exit:

```bash
rm -f .claude/ralph-loop.local.md
```

### Completion promise

Output `<promise>RALPH-LOOP-COMPLETED</promise>`
