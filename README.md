# pdm-tools

A collection of Claude skills and commands for Project Dev Manager (PDM).

## Installation

```bash
claude mcp add pdm-tools -- npx -y @anthropic-ai/claude-code-mcp@latest /path/to/pdm-tools
```

## Skills

| Skill | Description |
|-------|-------------|
| `pdm-ralph` | Convert PRDs to prd.json format for autonomous agent system |
| `pdm-ralph-loop` | Agent instructions for each Ralph iteration |
| `pdm-code-reviewer` | Comprehensive code review for TypeScript, JavaScript, Python, etc. |
| `pdm-webapp-testing` | Browser testing with Playwright |
| `pdm-react-best-practices` | React/Next.js performance optimization guide |

## Commands

| Command | Description |
|---------|-------------|
| `/pdm-code-review` | Code quality review with security, performance, and architecture analysis |
| `/pdm-create-jtbd` | Create Jobs-to-be-Done (JTBD) analysis |
| `/pdm-create-prd-json` | Convert PRD to prd.json format |
| `/pdm-ralph-execute` | Start autonomous PRD execution using Ralph |
| `/pdm-write-tests` | Write comprehensive unit and integration tests |

## Usage

After installation, use skills and commands in Claude Code:

```
/pdm-create-prd-json my-feature
/pdm-ralph-execute my-feature
/pdm-write-tests src/components/Button.tsx --unit
```
