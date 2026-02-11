# cc-automation-tools

A collection of Claude Code automation modules for planning, requirements, and autonomous feature development.

## Repo Structure

```
cc-automation-tools/
├── project-dev-manager/   # Planning & requirements
│   └── commands/
└── feature-builder-ralph/  # Autonomous feature execution
    ├── commands/
    └── agents/
```

## Modules

### Project Dev Manager

Tools for creating planning and requirements documents.

| Command | Description |
|---------|-------------|
| `/pdm-create-jtbd` | Create Jobs-to-be-Done document |
| `/pdm-create-prd` | Create Product Requirements Document (PRD) for new features |
| `/pdm-create-prd-json` | Convert PRD to prd.json |

### Feature Builder Ralph

Autonomous feature execution from a JSON feature spec. The `create-feature-from-json` command orchestrates the agents below to build, test, and validate each user story.

| Command | Description |
|---------|-------------|
| `/create-feature-from-json` | Create feature from user stories |

| Agent | Description |
|-------|-------------|
| `build-user-story` | Builds the solution for a user story per its acceptance criteria |
| `run-lint` | Runs linter and fixes violations |
| `run-playwright` | Runs Playwright E2E tests to visually validate a user story |
| `run-typecheck` | Runs TypeScript type checking and fixes errors |
| `write-tests` | Writes unit tests for a user story |

## Installation

```bash
claude mcp add cc-automation-tools -- npx -y @anthropic-ai/claude-code-mcp@latest /path/to/cc-automation-tools
```

## Usage

After installation, use commands in Claude Code:

```
# Planning & requirements
/pdm-create-jtbd my-feature
/pdm-create-prd my-feature
/pdm-create-prd-json my-feature

# Feature execution
/create-feature-from-json path/to/feature.json
```
