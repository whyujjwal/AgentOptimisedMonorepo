#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

ACTION="${1:-help}"
API_URL="${MEMORY_API_URL:-http://localhost:8000}"

function show_help() {
    cat << EOF
=== Agent Memory Skill ===

Store and recall important context using semantic search.

Usage:
  bash skills/memory/run.sh save "content" ["tag1,tag2"]
  bash skills/memory/run.sh recall "query" ["tag1,tag2"]
  bash skills/memory/run.sh list ["tag1,tag2"]

Examples:
  # Save a memory
  bash skills/memory/run.sh save "User prefers dark mode" "user_42,preferences"

  # Recall memories semantically
  bash skills/memory/run.sh recall "what are user preferences?" "user_42"

  # List all memories with a specific tag
  bash skills/memory/run.sh list "user_42"

Environment:
  MEMORY_API_URL  Base URL for the API (default: http://localhost:8000)
EOF
}

function save_memory() {
    local content="$1"
    local tags="${2:-}"
    
    echo "=== Saving memory ==="
    
    local tags_json="null"
    if [[ -n "$tags" ]]; then
        IFS=',' read -ra tag_array <<< "$tags"
        tags_json="$(printf '%s\n' "${tag_array[@]}" | jq -R . | jq -s .)"
    fi
    
    local response=$(curl -s -X POST "${API_URL}/memory/add" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg content "$content" --argjson tags "$tags_json" \
            '{content: $content, tags: $tags}')")
    
    echo "$response" | jq -r '.message // "Error: \(.)"'
}

function recall_memory() {
    local query="$1"
    local tags="${2:-}"
    
    echo "=== Recalling memories ==="
    
    local tags_json="null"
    if [[ -n "$tags" ]]; then
        IFS=',' read -ra tag_array <<< "$tags"
        tags_json="$(printf '%s\n' "${tag_array[@]}" | jq -R . | jq -s .)"
    fi
    
    local response=$(curl -s -X POST "${API_URL}/memory/search" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg query "$query" --argjson tags "$tags_json" \
            '{query: $query, tags: $tags, limit: 10}')")
    
    local count=$(echo "$response" | jq -r '.count // 0')
    
    if [[ "$count" -eq 0 ]]; then
        echo "No memories found for query: $query"
        return
    fi
    
    echo "Found $count memories:"
    echo ""
    echo "$response" | jq -r '.results[] | "[\(.score | . * 100 | floor)% match] \(.content)\n  ID: \(.id)\n  Metadata: \(.metadata)\n"'
}

function list_memories() {
    local tags="${1:-}"
    
    echo "=== Listing memories ==="
    
    # For now, use search with empty query to list
    local tags_json="null"
    if [[ -n "$tags" ]]; then
        IFS=',' read -ra tag_array <<< "$tags"
        tags_json="$(printf '%s\n' "${tag_array[@]}" | jq -R . | jq -s .)"
    fi
    
    local response=$(curl -s -X POST "${API_URL}/memory/search" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg query "" --argjson tags "$tags_json" \
            '{query: $query, tags: $tags, limit: 20}')")
    
    local count=$(echo "$response" | jq -r '.count // 0')
    
    if [[ "$count" -eq 0 ]]; then
        echo "No memories found"
        if [[ -n "$tags" ]]; then
            echo "  (with tags: $tags)"
        fi
        return
    fi
    
    echo "Found $count memories:"
    echo ""
    echo "$response" | jq -r '.results[] | "• \(.content)\n  ID: \(.id) | Tags: \(.metadata.tags // "none")\n"'
}

case "$ACTION" in
    save)
        CONTENT="${2:?Error: content required for save}"
        TAGS="${3:-}"
        save_memory "$CONTENT" "$TAGS"
        ;;
    recall)
        QUERY="${2:?Error: query required for recall}"
        TAGS="${3:-}"
        recall_memory "$QUERY" "$TAGS"
        ;;
    list)
        TAGS="${2:-}"
        list_memories "$TAGS"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Error: Unknown action '$ACTION'"
        echo ""
        show_help
        exit 1
        ;;
esac
