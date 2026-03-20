# init — Template Initialization

One-time script to customize this monorepo template for your project. Renames all hardcoded identifiers across the entire repo and optionally scaffolds an MCP server.

## Usage

```bash
# Interactive (prompts for all values)
bash skills/init/run.sh

# Non-interactive (all values via env vars)
PROJECT_NAME="My App" PROJECT_SLUG="my-app" PACKAGE_SCOPE="myorg" DESCRIPTION="My awesome app" SETUP_MCP=y \
  bash skills/init/run.sh
```

## What it prompts for

| Input | Example | Default |
|-------|---------|---------|
| Project name | `My Awesome App` | *(required)* |
| Project slug | `my-awesome-app` | Auto-derived from name |
| Package scope | `myorg` (becomes `@myorg/`) | `repo` |
| Description | `A SaaS platform for X` | `A modern full-stack application` |
| Create MCP server? | `y` / `n` | `n` |

## What gets replaced

| Old value | New value | Files affected |
|-----------|-----------|----------------|
| `AI-Native Monorepo API` | `{name} API` | `config.py`, `.env.example`, `openapi.json` |
| `AI-Native Monorepo` | `{name}` | `AGENTS.md`, `Makefile`, `README.md`, etc. |
| `ai-native-monorepo` | `{slug}` | `package.json`, `pyproject.toml` |
| `@repo/*` | `@{scope}/*` | Package configs, imports, skill files |
| `Create Next App` | `{name}` | `layout.tsx` metadata |
| `monorepo_postgres` | `{prefix}_postgres` | `docker-compose.yml` |
| `POSTGRES_*=monorepo` | `POSTGRES_*={db_name}` | `.env.example`, `docker-compose.yml` |
| `GAR_REPO=monorepo` | `GAR_REPO={slug}` | `Makefile`, deploy files |
| GitHub URL | `YOUR_ORG/{slug}` | `README.md` |

## MCP Server (optional)

If you say yes to the MCP prompt, the script creates `packages/mcp-server/` with:

```
packages/mcp-server/
├── src/
│   ├── index.ts          # Server entry (stdio transport)
│   └── tools/
│       └── index.ts      # Tool registry (hello tool included)
├── package.json          # @{scope}/mcp-server
├── tsconfig.json
└── README.md
```

Uses `@modelcontextprotocol/sdk`. Add tools in `src/tools/index.ts`, build with `pnpm build`, and configure in Claude Desktop or Claude Code. See `packages/mcp-server/README.md` after creation.

## After running

1. Review the changes (`git diff` if git history was kept)
2. Edit `.env` files with real secrets
3. Run `make dev` to start developing
4. If MCP was created: `pnpm --filter @{scope}/mcp-server build`
