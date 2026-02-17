# checkpoint

Creates a versioned snapshot of the codebase with Entire context tracking.

## When to use
- After completing a logical unit of work
- Before attempting a risky refactor
- When switching between tasks

## What happens
1. Stages all changes
2. Creates a git commit with a `checkpoint:` prefix
3. Entire CLI hooks auto-capture agent context and reasoning

## Usage
```bash
bash skills/checkpoint/run.sh "auth feature complete"
```

## How Entire Works
- Entire hooks are configured in `.claude/settings.json`
- On every commit, Entire snapshots the agent's thought process
- Use `entire log` to browse past checkpoints
- Use `entire diff <checkpoint-id>` to see what changed
