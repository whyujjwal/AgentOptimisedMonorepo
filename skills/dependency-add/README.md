# dependency-add

Adds a dependency using the correct package manager for this monorepo.

## When to use
Whenever you need to add a new package. Never use `npm install` or `pip install` directly.

## Usage
```bash
# JavaScript/TypeScript (requires workspace filter)
bash skills/dependency-add/run.sh js zod web
bash skills/dependency-add/run.sh js react-icons @repo/ui

# Python
bash skills/dependency-add/run.sh py httpx
```
