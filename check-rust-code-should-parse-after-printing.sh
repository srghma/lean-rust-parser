#!/usr/bin/env bash
# Verify that Lean's edition-specific pretty-printed Rust corpora pass rustc.
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUSTC_BIN="${RUSTC:-/nix/store/rmxivbf491cgv8ysclad7ss62l5acqlf-rustc-1.98.0-nightly-2026-06-30-x86_64-unknown-linux-gnu/bin/rustc}"
editions=(2015 2018 2021 2024)

if [[ ! -x "$RUSTC_BIN" ]]; then
  echo "rustc is not executable: $RUSTC_BIN" >&2
  exit 1
fi

failures=0
total=0
for edition in "${editions[@]}"; do
  printed_dir="$REPO_ROOT/LeanRustParserTests/rust-code-should-parse-on-$edition--output-of-lean-prettyprint"
  if [[ ! -d "$printed_dir" ]]; then
    echo "Missing pretty-printed corpus for edition $edition: $printed_dir" >&2
    failures=$((failures + 1))
    continue
  fi

  while IFS= read -r -d '' file; do
    total=$((total + 1))
    if ! RUSTC_BOOTSTRAP=1 "$RUSTC_BIN" \
        -Z parse-crate-root-only \
        --crate-type lib \
        --edition "$edition" \
        "$file" >/dev/null 2> /tmp/check-rust-code-should-parse-after-printing.err; then
      echo "rustc rejected [$edition]: ${file#$printed_dir/}" >&2
      cat /tmp/check-rust-code-should-parse-after-printing.err >&2
      failures=$((failures + 1))
    fi
  done < <(find "$printed_dir" -type f -name '*.rs' -print0 | LC_ALL=C sort -z)
done

if (( failures != 0 )); then
  echo "rustc rejected $failures of $total pretty-printed fixtures." >&2
  exit 1
fi

echo "rustc accepted all $total edition-specific pretty-printed fixtures."
