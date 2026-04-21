#!/bin/bash
# USP Codegen Script
# Generate Dart code from USP YAML definitions (GitHub or local)
#
# Usage:
#   ./tools/usp-codegen.sh                    # Fetch from GitHub (latest)
#   ./tools/usp-codegen.sh --local <path>     # Use local path
#   ./tools/usp-codegen.sh --branch <name>    # Specify GitHub branch
#   ./tools/usp-codegen.sh --watch            # Watch mode (--local only)
#
# Environment variables:
#   USP_DEFINITIONS_REPO   GitHub repo (default: linksys/usp_framework)
#   USP_DEFINITIONS_LOCAL  Local path (overrides GitHub when set)

set -e

# === Configuration ===
REPO="${USP_DEFINITIONS_REPO:-linksys/usp_framework}"
BRANCH="main"
CACHE_DIR="${HOME}/.cache/usp-definitions"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL_PATH=""
WATCH_MODE=false

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# === Parse arguments ===
while [[ $# -gt 0 ]]; do
    case $1 in
        --local|-l)
            LOCAL_PATH="$2"
            shift 2
            ;;
        --branch|-b)
            BRANCH="$2"
            shift 2
            ;;
        --watch|-w)
            WATCH_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --local, -l <path>   Use local definitions path"
            echo "  --branch, -b <name>  Specify GitHub branch (default: main)"
            echo "  --watch, -w          Watch mode, regenerate on file changes"
            echo "  --help, -h           Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                              # Fetch from GitHub main branch"
            echo "  $0 --branch feature/new-api    # Fetch from specific branch"
            echo "  $0 --local ../usp-definitions  # Use local path"
            echo "  $0 --local ../usp-definitions --watch  # Local + watch mode"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Environment variable override
if [[ -z "$LOCAL_PATH" && -n "$USP_DEFINITIONS_LOCAL" ]]; then
    LOCAL_PATH="$USP_DEFINITIONS_LOCAL"
fi

# === Functions ===

fetch_from_github() {
    echo -e "${BLUE}> Fetching definitions from GitHub...${NC}"
    echo "  Repo: $REPO"
    echo "  Branch: $BRANCH"

    if [[ -d "$CACHE_DIR/.git" ]]; then
        # Already exists, fetch + checkout
        cd "$CACHE_DIR"
        git fetch origin "$BRANCH" --depth=1 -q
        git checkout -q FETCH_HEAD
        cd - > /dev/null
        echo -e "  ${GREEN}Updated${NC}"
    else
        # First time clone
        echo "  Downloading..."
        rm -rf "$CACHE_DIR"
        git clone --depth=1 --branch "$BRANCH" \
            "https://github.com/${REPO}.git" "$CACHE_DIR" -q
        echo -e "  ${GREEN}Done${NC}"
    fi

    # Auto-detect definitions directory
    if [[ -d "$CACHE_DIR/definitions" ]]; then
        DEFINITIONS_DIR="$CACHE_DIR/definitions"
    elif [[ -d "$CACHE_DIR/usp-definitions" ]]; then
        DEFINITIONS_DIR="$CACHE_DIR/usp-definitions"
    else
        echo "Error: No definitions directory found in repo"
        echo "  Tried: $CACHE_DIR/definitions"
        echo "         $CACHE_DIR/usp-definitions"
        exit 1
    fi
}

run_codegen() {
    local defs_dir="$1"

    echo -e "${BLUE}> Running codegen...${NC}"
    echo "  Source: $defs_dir"
    echo "  Output: $ROOT/lib/generated"

    "$ROOT/tools/usp-codegen" \
        --definitions-dir "$defs_dir" \
        --output-dir "$ROOT/lib/generated" \
        --language dart \
        --client-import 'package:privacy_gui/core/usp/services/usp_client.dart' \
        --client-class 'UspClient'

    local count=$(ls -1 "$ROOT/lib/generated"/*.g.dart 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}Generated ${count} files${NC}"

    # Format generated code
    echo -e "${BLUE}> Formatting generated code...${NC}"
    dart format "$ROOT/lib/generated"
    echo -e "${GREEN}Done${NC}"
}

# === Main ===

echo ""
echo "======================================="
echo "  USP Codegen"
echo "======================================="
echo ""

if [[ -n "$LOCAL_PATH" ]]; then
    # Local mode
    DEFINITIONS_DIR="$(cd "$LOCAL_PATH" && pwd)/definitions"

    if [[ ! -d "$DEFINITIONS_DIR" ]]; then
        # Maybe pointing directly to definitions directory
        if [[ -d "$LOCAL_PATH" && -f "$LOCAL_PATH"/*.yaml ]]; then
            DEFINITIONS_DIR="$(cd "$LOCAL_PATH" && pwd)"
        else
            echo "Error: definitions directory not found"
            echo "  Tried: $DEFINITIONS_DIR"
            exit 1
        fi
    fi

    echo -e "${YELLOW}> Local mode${NC}"
    echo "  Path: $DEFINITIONS_DIR"

    if $WATCH_MODE; then
        echo ""
        echo -e "${YELLOW}> Watch mode started${NC}"
        echo "  Press Ctrl+C to stop"
        echo ""

        if ! command -v watchexec &> /dev/null; then
            echo "Error: watchexec required"
            echo "  Install: brew install watchexec"
            exit 1
        fi

        # Run once first
        run_codegen "$DEFINITIONS_DIR"
        echo ""
        echo "Watching for changes..."

        watchexec -w "$DEFINITIONS_DIR" -e yaml -- "$0" --local "$LOCAL_PATH"
    else
        run_codegen "$DEFINITIONS_DIR"
    fi
else
    # Remote mode
    if $WATCH_MODE; then
        echo "Error: --watch can only be used with --local"
        exit 1
    fi

    fetch_from_github
    run_codegen "$DEFINITIONS_DIR"
fi

echo ""
