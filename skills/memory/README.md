# memory

Agent-accessible skill for saving and recalling context using a local vector database.

## When to use
- Before starting a task: recall past decisions, preferences, or known issues
- After making a key decision: save it so future sessions remember it
- Any time you learn something worth remembering

## What happens
- `save` — embeds your text into ChromaDB and persists it to `.data/chromadb/`
- `recall` — semantic search: finds memories by meaning, not just keywords
- `list` — lists all memories, optionally filtered by tag

## Usage
```bash
# Save a memory
bash skills/memory/run.sh save "content" ["tag1,tag2"]

# Recall by semantic similarity
bash skills/memory/run.sh recall "query" ["tag1"]

# List memories (optionally by tag)
bash skills/memory/run.sh list ["tag1"]
```

## Examples
```bash
# Save architecture decisions
bash skills/memory/run.sh save "We use cursor-based pagination, not offset, for all list endpoints" "api,decisions"

# Save user preferences
bash skills/memory/run.sh save "User always wants TypeScript strict mode, no any types" "user,typescript"

# Recall semantically — finds the above even without exact keywords
bash skills/memory/run.sh recall "how should we handle listing resources?"

# Tag-filtered list
bash skills/memory/run.sh list "decisions"
```

## How it works
Backed by **ChromaDB** — a local vector database that stores data in `.data/chromadb/` inside the repo. No external API, no account, no data leaves the machine. Uses cosine similarity for semantic search.
