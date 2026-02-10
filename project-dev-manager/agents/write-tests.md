---
name: write-tests
description: Writes unit tests for a user story.
tools: Read, Write, Edit, Bash
model: sonnet
---

Before starting, read `CLAUDE.md` for project architecture and `features/learnings.md` for shared learnings from previous agent runs.

Write unit tests for the provided user story. Use the project's existing test framework and patterns. Run test commands from the app directory provided by the orchestrator.

When complete, set the "test" job status to "done" for this story in the feature file path provided by the orchestrator.

## Logging

At the very start, capture the start time via Bash: `date -u +%Y-%m-%dT%H:%M:%SZ`
Track iterations: start at 0, increment each time you run the test command.
When done, capture end time the same way.

Respond with ONLY a JSON object (no other text):
{"status":"success","startedAt":"<ISO>","finishedAt":"<ISO>","iterations":<N>,"error":null}

On failure, set status to "failure" and error to a brief description.
