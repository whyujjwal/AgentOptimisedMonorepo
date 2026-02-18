# Rule: Task List Management (Execution Mode)

You are executing an engineering task list one sub-task at a time.
You will be given `@tasks/TASKS.md` as context.

## Behaviour

### Starting execution
1. Read `tasks/TASKS.md` to find the **first uncompleted sub-task** (first `- [ ]` leaf item).
2. State clearly which task you are about to work on.
3. Implement it — write the code, run the relevant skill, or make the change.
4. **Stop and wait for user confirmation** before moving to the next task.

### After each task
1. Update `tasks/TASKS.md`: mark the completed sub-task with `[x]`.
2. If all sub-tasks under a parent are done, mark the parent `[x]` too.
3. Show the user the updated checklist for the current phase.
4. Print: `✓ Task complete. Type "yes" to continue to the next task, or describe any issues.`
5. **Do not proceed until the user types "yes" (or equivalent confirmation).**

### If a task fails or blocks
- Mark it `[~]` (in progress / blocked) in `tasks/TASKS.md`.
- Explain the blocker clearly.
- Propose a resolution or ask the user for guidance.
- Do not skip tasks or work around blockers silently.

### Skill triggers during execution
When a task involves these changes, run the corresponding skill **as part of that task**:
- Modified `apps/api/app/schemas/` → `bash skills/type-sync/run.sh`
- Modified `apps/api/app/models/` → `bash skills/db-migrate/run.sh`
- Added a dependency → `bash skills/dependency-add/run.sh <pkg> <ecosystem>`
- Before marking any phase complete → `bash skills/lint-fix/run.sh`

### Completing all tasks
When every task in `tasks/TASKS.md` is marked `[x]`:
1. Run `bash skills/test-run/run.sh`
2. Run `bash skills/lint-fix/run.sh`
3. Summarise what was built, referencing the acceptance criteria in `tasks/PRD.md`.
4. Run `bash skills/checkpoint/run.sh "<feature-name> complete"` to snapshot the work.
5. Suggest next steps or related improvements if obvious.

## Invariants

- **One sub-task at a time.** Never implement multiple sub-tasks in a single response.
- **Always update `tasks/TASKS.md` before reporting completion** of a task.
- **Never skip a task** without explicit user instruction.
- **Context is the PRD.** If a task is ambiguous, re-read `tasks/PRD.md` before asking the user.
