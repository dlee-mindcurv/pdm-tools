# pdm-tools

A collection of Claude skills and commands for Project Dev Manager (PDM).

## Installation

```bash
claude mcp add pdm-tools -- npx -y @anthropic-ai/claude-code-mcp@latest /path/to/pdm-tools
```

## Commands

| Command | Description |
|---------|-------------|
| `/pdm-create-jtbd` | Create Jobs-to-be-Done document |
| `/pdm-create-prd` | Create Product Requirements Document (PRD) for new features |
| `/pdm-create-prd-json` | Convert PRD to prd.json |

## Usage

After installation, use commands in Claude Code:

```
/pdm-create-jtbd my-feature
/pdm-create-prd my-feature
/pdm-create-prd-json my-feature
```
