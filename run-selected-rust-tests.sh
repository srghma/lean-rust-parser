#!/usr/bin/env bash
set -euo pipefail

# Keep fixtures that currently require a Basic AST/model change here.
except=(
  survive-peano-lesson-queue-tttt.rs
  macro--issue-33569-tttt.rs
  missing-semicolon-tttt.rs
  anon-enums-are-ambiguous-tttt.rs
  async-with-nonterminal-block-fttt.rs
  attribute--attr-bad-meta-4-tttt.rs
  attribute--attr-incomplete-tttt.rs
  attribute--attr-unquoted-ident-tttt.rs
  attribute--properly-recover-from-trailing-outer-attribute-in-body-2-tttt.rs
  bad-recover-kw-after-impl-tttt.rs
  bad-recover-ty-after-impl-tttt.rs
  bastion-of-the-turbofish-tttt.rs
  bounds-obj-parens-tttt.rs
  const-block-items--attrs-tttt.rs
  const-block-items--macro-item-tttt.rs
  const-block-items--macro-stmt-tttt.rs
  float-field-interpolated-tttt.rs
  issues--issue-33418-tttt.rs
  impl-item-const-pass-tttt.rs
  impl-item-const-semantic-fail-tttt.rs
  impl-item-fn-no-body-pass-tttt.rs
  impl-item-fn-no-body-semantic-fail-tttt.rs
  impl-item-type-no-body-pass-tttt.rs
  impl-item-type-no-body-semantic-fail-tttt.rs
  self-param-syntactic-pass-tttt.rs
)

join_by_pipe() {
  local IFS='|'
  printf '%s' "$*"
}

args=(--compact-output)
if ((${#except[@]})); then
  args+=("--except=$(join_by_pipe "${except[@]}")")
fi

lake test -- "${args[@]}"
