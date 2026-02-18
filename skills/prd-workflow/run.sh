#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

COMMAND="${1:-help}"
FEATURE="${2:-feature}"

TASKS_DIR="$REPO_ROOT/tasks"
RULES_DIR="$REPO_ROOT/rules"
ARCHIVE_DIR="$REPO_ROOT/tasks/archive"

function show_help() {
    cat << 'EOF'
=== PRD Workflow Skill ===

Ryan Carson's 3-step structured AI coding workflow.

Usage:
  bash skills/prd-workflow/run.sh init              # Start a new feature
  bash skills/prd-workflow/run.sh status            # Show task list progress
  bash skills/prd-workflow/run.sh reset <name>      # Archive current tasks, start fresh

Workflow (after running init):
  Step 1 — PRD:   Reference @rules/generate_prd.md + describe your feature
  Step 2 — Tasks: Reference @rules/generate_tasks.md @tasks/PRD.md
  Step 3 — Build: Reference @rules/task_list_management.md @tasks/TASKS.md

Rule files: rules/generate_prd.md, rules/generate_tasks.md, rules/task_list_management.md
Task files: tasks/PRD.md, tasks/TASKS.md
EOF
}

function cmd_init() {
    echo "=== PRD Workflow: Init ==="
    echo ""

    # Ensure rule files exist
    local missing=0
    for rule in generate_prd generate_tasks task_list_management; do
        if [[ ! -f "$RULES_DIR/${rule}.md" ]]; then
            echo "ERROR: Missing rule file: rules/${rule}.md"
            missing=1
        fi
    done
    if [[ "$missing" -eq 1 ]]; then
        echo "Run from repo root. Rule files must exist in rules/."
        exit 1
    fi

    # Create tasks dir
    mkdir -p "$TASKS_DIR"

    # Warn if stale PRD/TASKS already exist
    if [[ -f "$TASKS_DIR/PRD.md" ]] || [[ -f "$TASKS_DIR/TASKS.md" ]]; then
        echo "⚠️  WARNING: tasks/PRD.md or tasks/TASKS.md already exists."
        echo "   Run 'bash skills/prd-workflow/run.sh reset <feature-name>' to archive and start fresh."
        echo ""
    fi

    cat << 'EOF'
✓ Ready. Follow these 3 steps in your AI agent:

─────────────────────────────────────────────────────
STEP 1 — Generate PRD
─────────────────────────────────────────────────────
In your agent, type:
  @rules/generate_prd.md I want to build: <describe your feature>

The agent will ask clarifying questions, then write tasks/PRD.md.

─────────────────────────────────────────────────────
STEP 2 — Generate Task List
─────────────────────────────────────────────────────
After PRD is written, type:
  @rules/generate_tasks.md @tasks/PRD.md

The agent proposes a high-level plan (approve it), then writes tasks/TASKS.md.

─────────────────────────────────────────────────────
STEP 3 — Execute Tasks (one at a time)
─────────────────────────────────────────────────────
Start execution:
  @rules/task_list_management.md @tasks/TASKS.md

The agent completes one sub-task, then pauses. Type "yes" to continue.
─────────────────────────────────────────────────────
EOF
}

function cmd_status() {
    echo "=== PRD Workflow: Status ==="
    echo ""

    if [[ ! -f "$TASKS_DIR/TASKS.md" ]]; then
        echo "No tasks/TASKS.md found. Run 'init' and complete Step 2 first."
        exit 0
    fi

    local total done in_progress
    total=$(grep -c '^\s*- \[' "$TASKS_DIR/TASKS.md" 2>/dev/null || echo 0)
    done=$(grep -c '^\s*- \[x\]' "$TASKS_DIR/TASKS.md" 2>/dev/null || echo 0)
    in_progress=$(grep -c '^\s*- \[~\]' "$TASKS_DIR/TASKS.md" 2>/dev/null || echo 0)
    local pending=$(( total - done - in_progress ))

    echo "Task file: tasks/TASKS.md"
    echo ""
    echo "  Total:       $total"
    echo "  Done [x]:    $done"
    echo "  In progress: $in_progress"
    echo "  Pending:     $pending"
    echo ""

    if [[ "$done" -eq "$total" ]] && [[ "$total" -gt 0 ]]; then
        echo "🎉 All tasks complete!"
    else
        echo "--- Remaining tasks ---"
        grep '^\s*- \[ \]\|^\s*- \[~\]' "$TASKS_DIR/TASKS.md" | head -20 || echo "(none)"
    fi
}

function cmd_reset() {
    echo "=== PRD Workflow: Reset ==="
    echo ""

    mkdir -p "$ARCHIVE_DIR"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local archive_name="${timestamp}-${FEATURE}"

    if [[ -f "$TASKS_DIR/PRD.md" ]] || [[ -f "$TASKS_DIR/TASKS.md" ]]; then
        mkdir -p "$ARCHIVE_DIR/$archive_name"
        [[ -f "$TASKS_DIR/PRD.md" ]]   && mv "$TASKS_DIR/PRD.md"   "$ARCHIVE_DIR/$archive_name/"
        [[ -f "$TASKS_DIR/TASKS.md" ]] && mv "$TASKS_DIR/TASKS.md" "$ARCHIVE_DIR/$archive_name/"
        echo "✓ Archived to tasks/archive/$archive_name/"
    else
        echo "Nothing to archive (no PRD.md or TASKS.md in tasks/)."
    fi

    echo ""
    echo "Run 'bash skills/prd-workflow/run.sh init' to start a new feature."
}

case "$COMMAND" in
    init)
        cmd_init
        ;;
    status)
        cmd_status
        ;;
    reset)
        cmd_reset
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo ""
        show_help
        exit 1
        ;;
esac
