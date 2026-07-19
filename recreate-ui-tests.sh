#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="/home/srghma/projects/rust/tests/ui/parser"
DST_DIR="/home/srghma/projects/lean-rust-parser/rust-tests-ui-parser"

echo "Recreating directory $DST_DIR..."
rm -rf "$DST_DIR"
mkdir -p "$DST_DIR"
cp -r "$SRC_DIR"/. "$DST_DIR"/

echo "Analyzing tests..."

SUCCEED_TESTS=()
FAIL_TESTS=()

while IFS= read -r -d '' rs_file; do
    rel_path="${rs_file#$DST_DIR/}"
    base_name="${rs_file%.rs}"

    is_pass=false

    # Check for explicit pass annotations in the file or filename
    if grep -q -E -i "//@.*(check|run|build)-pass|//.*(check|run|build)-pass" "$rs_file"; then
        is_pass=true
    elif [[ "$rel_path" == *-rpass.rs ]]; then
        is_pass=true
    fi

    # If not explicitly pass, check if there are error annotations or a stderr file
    if [ "$is_pass" = false ]; then
        if ls "${base_name}"*.stderr >/dev/null 2>&1; then
            is_pass=false
        elif grep -q "//~" "$rs_file"; then
            is_pass=false
        else
            # Default to succeed if there are no error expectations
            is_pass=true
        fi
    fi

    if [ "$is_pass" = true ]; then
        SUCCEED_TESTS+=("$rel_path")
    else
        FAIL_TESTS+=("$rel_path")
    fi
done < <(find "$DST_DIR" -type f -name "*.rs" -print0 | sort -z)

echo ""
echo "=== TESTS THAT SHOULD SUCCEED ==="
for t in "${SUCCEED_TESTS[@]}"; do
    echo "  $t"
done

echo ""
echo "=== TESTS THAT SHOULD FAIL ==="
for t in "${FAIL_TESTS[@]}"; do
    echo "  $t"
done

echo ""
echo "Summary:"
echo "  Total tests: $(( ${#SUCCEED_TESTS[@]} + ${#FAIL_TESTS[@]} ))"
echo "  Should succeed: ${#SUCCEED_TESTS[@]}"
echo "  Should fail: ${#FAIL_TESTS[@]}"
