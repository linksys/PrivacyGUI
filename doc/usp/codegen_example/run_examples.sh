#!/bin/bash
# Script to generate code from all example definitions
# Demonstrates the code generator with real-world examples

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEGEN_BIN="${SCRIPT_DIR}/../bin/usp-codegen"
EXAMPLES_DIR="${SCRIPT_DIR}"
OUTPUT_BASE="${SCRIPT_DIR}/generated"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if codegen binary exists
if [ ! -f "$CODEGEN_BIN" ]; then
    echo -e "${RED}Error: usp-codegen binary not found at $CODEGEN_BIN${NC}"
    echo "Please run 'make' in the usp-codegen directory first."
    exit 1
fi

echo "========================================"
echo "USP Code Generator - Example Runner"
echo "========================================"
echo

# Clean previous output
echo "Cleaning previous generated code..."
rm -rf "$OUTPUT_BASE"

# Per-language client configuration
# Examples use a local stub so they are self-contained (no Flutter dependency).
# Production builds should override --client-import to point at the real client.
get_client_import() {
    case "$1" in
        dart)       echo "../../stubs/dart/usp_client.dart" ;;
        typescript) echo "usp-client" ;;
        swift)      echo "UspClient" ;;
    esac
}
get_client_class() {
    case "$1" in
        dart)       echo "UspClient" ;;
        typescript) echo "UspClient" ;;
        swift)      echo "UspClient" ;;
    esac
}

# Generate for each language
LANGUAGES=("dart" "typescript" "swift")

for LANG in "${LANGUAGES[@]}"; do
    echo
    echo -e "${YELLOW}Generating $LANG code...${NC}"
    OUTPUT_DIR="${OUTPUT_BASE}/${LANG}"

    # Build language-specific extra flags
    EXTRA_FLAGS=""
    if [ "$LANG" = "dart" ]; then
        EXTRA_FLAGS="--dart-tr ../../stubs/dart/tr.dart"
    fi

    "$CODEGEN_BIN" \
        --definitions-dir "$EXAMPLES_DIR" \
        --output-dir "$OUTPUT_DIR" \
        --language "$LANG" \
        --client-import "$(get_client_import "$LANG")" \
        --client-class "$(get_client_class "$LANG")" \
        $EXTRA_FLAGS

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $LANG generation completed successfully${NC}"
        echo "  Output: $OUTPUT_DIR"

        # List generated files
        echo "  Generated files:"
        find "$OUTPUT_DIR" -type f | sed 's|^|    - |'
    else
        echo -e "${RED}✗ $LANG generation failed${NC}"
        exit 1
    fi
done

echo
echo "========================================"
echo -e "${GREEN}All examples generated successfully!${NC}"
echo "========================================"
echo
echo "Generated code locations:"
echo "  - Dart:       $OUTPUT_BASE/dart"
echo "  - TypeScript: $OUTPUT_BASE/typescript"
echo "  - Swift:      $OUTPUT_BASE/swift"
echo
