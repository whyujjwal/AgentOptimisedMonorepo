# Rule: Generate Task List from PRD

You are a senior engineer converting a PRD into an actionable engineering task list.
You will be given `@tasks/PRD.md` as context.

## Behaviour

1. Read the PRD carefully.
2. **Propose a high-level plan** — a brief outline of the major phases of work.
   - Present this to the user and **wait for approval** before proceeding.
   - Do not generate the full task list until the user confirms.
   - Example: "Here's my proposed approach: (1) DB migration, (2) API endpoints, (3) Frontend page. Shall I break these into sub-tasks?"

3. After approval, generate `tasks/TASKS.md` with the full nested task list.

## Task List Format

```markdown
# Tasks: <Feature Name>

> Generated from: tasks/PRD.md
> Status: [ ] = pending, [x] = done, [~] = in progress

## Phase 1: <Phase Name>

- [ ] 1.1 <Parent task description>
  - [ ] 1.1.1 <Sub-task — specific, single action, testable>
  - [ ] 1.1.2 <Sub-task>
- [ ] 1.2 <Parent task description>
  - [ ] 1.2.1 <Sub-task>

## Phase 2: <Phase Name>

- [ ] 2.1 ...
```

## Rules for Good Tasks

- **Atomic**: each sub-task should be completable in a single focused change
- **Testable**: you must be able to verify it's done (a test, a visible UI change, a passing API call)
- **Ordered**: tasks must be in dependency order — no task depends on an incomplete predecessor
- **File-specific where possible**: mention the file to create or edit (e.g., "Create `apps/api/app/routers/orders.py`")
- **No ambiguity**: instead of "add validation", say "Add Pydantic validator to reject negative `quantity` in `OrderCreateSchema`"

## Monorepo-specific guidance

Follow the zones defined in `CLAUDE.md`:
- Backend tasks → `apps/api/`
- Frontend tasks → `apps/web/`
- Shared types → run `bash skills/type-sync/run.sh` after schema changes (add as a sub-task)
- DB model changes → run `bash skills/db-migrate/run.sh` (add as a sub-task)
- New dependencies → use `bash skills/dependency-add/run.sh` (add as a sub-task)

Always include a final phase for verification:
```markdown
## Phase N: Verification

- [ ] N.1 Run `bash skills/test-run/run.sh` and confirm all tests pass
- [ ] N.2 Run `bash skills/lint-fix/run.sh` and confirm no lint errors
- [ ] N.3 Verify acceptance criteria in `tasks/PRD.md` are all met
```

## Output

- File: `tasks/TASKS.md`
- After writing the file, confirm: "Task list written to `tasks/TASKS.md`. Reference `@rules/task_list_management.md` with `@tasks/TASKS.md` to begin execution."
