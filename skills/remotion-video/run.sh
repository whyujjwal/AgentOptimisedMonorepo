#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

# Parse arguments
COMMAND="${1:-help}"
COMPOSITION_ID="${2:-}"
OUTPUT_FILE="${3:-dist/video.mp4}"
PROPS="${4:-}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
  cat << 'EOF'
remotion-video skill — Generate videos using Remotion

Usage:
  bash skills/remotion-video/run.sh render <composition-id> [output-file] [props-json]
  bash skills/remotion-video/run.sh preview <composition-id> [props-json]
  bash skills/remotion-video/run.sh install
  bash skills/remotion-video/run.sh help

Commands:
  render       Render a video composition to file
  preview      Start preview server for a composition
  install      Install Remotion dependencies in apps/web
  help         Show this help message

Examples:
  # Render a simple intro video
  bash skills/remotion-video/run.sh render MyIntroVideo output.mp4

  # Render with custom props (JSON string)
  bash skills/remotion-video/run.sh render MyVideo output.mp4 '{"title":"Hello World","duration":5}'

  # Start preview server
  bash skills/remotion-video/run.sh preview MyIntroVideo

  # Install Remotion
  bash skills/remotion-video/run.sh install

EOF
}

install_remotion() {
  echo -e "${BLUE}=== Installing Remotion dependencies ===${NC}"

  cd "$REPO_ROOT/apps/web"

  echo -e "${YELLOW}Installing @remotion/cli...${NC}"
  pnpm add -D remotion @remotion/cli @remotion/player

  echo -e "${YELLOW}Installing FFmpeg (system dependency)...${NC}"
  if command -v brew &> /dev/null; then
    echo "Detected macOS — installing FFmpeg via Homebrew"
    brew install ffmpeg
  elif command -v apt-get &> /dev/null; then
    echo "Detected Debian/Ubuntu — installing FFmpeg via apt"
    sudo apt-get install -y ffmpeg
  else
    echo -e "${YELLOW}Please install FFmpeg manually: https://ffmpeg.org/download.html${NC}"
  fi

  echo -e "${GREEN}=== Remotion installation complete ===${NC}"
}

render_video() {
  if [ -z "$COMPOSITION_ID" ]; then
    echo -e "${YELLOW}Error: composition-id is required${NC}"
    show_help
    exit 1
  fi

  echo -e "${BLUE}=== Rendering Remotion video ===${NC}"
  echo "Composition: $COMPOSITION_ID"
  echo "Output file: $OUTPUT_FILE"

  cd "$REPO_ROOT/apps/web"

  # Build the command
  RENDER_CMD="pnpm remotion render $COMPOSITION_ID $OUTPUT_FILE"

  if [ -n "$PROPS" ]; then
    echo "Props: $PROPS"
    RENDER_CMD="$RENDER_CMD --props '$PROPS'"
  fi

  echo -e "${YELLOW}Running: $RENDER_CMD${NC}"
  eval "$RENDER_CMD"

  if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    echo -e "${GREEN}✓ Video rendered successfully${NC}"
    echo "Output: $OUTPUT_FILE ($SIZE)"
  else
    echo -e "${YELLOW}Warning: Output file not found at $OUTPUT_FILE${NC}"
    exit 1
  fi
}

preview_video() {
  if [ -z "$COMPOSITION_ID" ]; then
    echo -e "${YELLOW}Error: composition-id is required${NC}"
    show_help
    exit 1
  fi

  echo -e "${BLUE}=== Starting Remotion preview server ===${NC}"
  echo "Composition: $COMPOSITION_ID"

  cd "$REPO_ROOT/apps/web"

  PREVIEW_CMD="pnpm remotion preview"

  if [ -n "$PROPS" ]; then
    echo "Props: $PROPS"
    PREVIEW_CMD="$PREVIEW_CMD --props '$PROPS'"
  fi

  echo -e "${YELLOW}Running: $PREVIEW_CMD${NC}"
  echo -e "${GREEN}Preview server will open at http://localhost:3000${NC}"
  echo "Press Ctrl+C to stop the server"

  eval "$PREVIEW_CMD"
}

# Main dispatch
case "$COMMAND" in
  render)
    render_video
    ;;
  preview)
    preview_video
    ;;
  install)
    install_remotion
    ;;
  help)
    show_help
    ;;
  *)
    echo -e "${YELLOW}Unknown command: $COMMAND${NC}"
    show_help
    exit 1
    ;;
esac
