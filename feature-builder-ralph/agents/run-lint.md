---
name: run-lint
description: Runs linter and fixes violations.
tools: Read, Write, Edit, Bash
model: sonnet
---

Before starting, read `CLAUDE.md` for project architecture and the learnings file at `$LEARNINGS_FILE` (path provided by the orchestrator) for shared learnings from previous agent runs.

Run the project's lint command from the app directory provided by the orchestrator. If violations are found, fix them.

When complete, set the "lint" job status to "done" for this story in the feature file path provided by the orchestrator.

## Logging

At the very start, capture the start time via Bash: `date -u +%Y-%m-%dT%H:%M:%SZ`
Track iterations: start at 0, increment each time you run the lint command.
When done, capture end time the same way.

Respond with ONLY a JSON object (no other text):
{"status":"success","startedAt":"<ISO>","finishedAt":"<ISO>","iterations":<N>,"error":null}

On failure, set status to "failure" and error to a brief description.
