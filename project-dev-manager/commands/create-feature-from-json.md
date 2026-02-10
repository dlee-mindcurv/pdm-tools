---
name: create-feature-from-json
allowed-tools: Read, Write, Edit, Exit, Grep, Glob, Task, Bash
description: Create Feature from user stories
argument-hint: [path to feature JSON file]
---

The first argument is the path to the feature JSON file (e.g., `features/pink-footer/prd.json`). All references below use `$FEATURE_FILE` to mean that provided path.

Read `appDir` from the feature file with `jq -r '.appDir' $FEATURE_FILE`. All references below use `$APP_DIR` to mean this value (e.g., `example`).

## Log initialization

Derive the feature directory from `$FEATURE_FILE` (e.g., `features/pink-footer/`). Set `$LOG_FILE` to `<feature-dir>/agent-log.json`.

Check if this is a fresh start: use jq to test if the first story's jobs are ALL `"pending"`. If so (or if `$LOG_FILE` doesn't exist), create/reset `$LOG_FILE` to `[]`.

## Status check and dispatch

Run `jq '[.userStories[] | {id, passes, jobs: [.jobs[] | {name, status, dependsOn}]}]' $FEATURE_FILE` to check status.

1. If all userStories have `passes: true`, output `<promise>RALPH-LOOP-COMPLETED</promise>`
2. Find the first story where `passes: false`
3. Find runnable jobs: A job is runnable when its own status is `"pending"` AND (`dependsOn` is null OR the dependency job's status is `"done"`), **except**: the `playwright` job is runnable when its own status is `"pending"` AND the `build` job's status is `"generated"`. All other jobs continue to gate on `"done"`.
4. Before dispatching agents, capture: `BATCH_START=$(date -u +%Y-%m-%dT%H:%M:%SZ)`. Then invoke each runnable job's agent in parallel via Task tool (read the full story data with `jq '.userStories[INDEX]' $FEATURE_FILE` to pass to each). **Include both the feature file path and the app directory in each agent's prompt** so the agent knows which file to update and where the application code lives. After all Task calls return, capture: `BATCH_END=$(date -u +%Y-%m-%dT%H:%M:%SZ)`.

## Write log entries

For each agent that ran, parse its JSON response. Construct a log entry object with:
- `storyId`, `job`, `agent` from the dispatch context
- `status`, `iterations`, `error` from the agent's JSON response
- `startedAt`/`finishedAt` from the agent's JSON response; if either is `null`, substitute `$BATCH_START`/`$BATCH_END` respectively

Read `$LOG_FILE`, append the new entries to the array, and write it back.

The agent-to-job mapping is: `build-user-story` → `build`, `run-lint` → `lint`, `run-typecheck` → `typecheck`, `write-tests` → `test`, `run-playwright` → `playwright`.

## Finalize story

5. After all jobs for the story are `done`, set `passes: true` in `$FEATURE_FILE`