#!/usr/bin/env bash
set -euo pipefail

only=(
bad-interpolated-block-tttt.rs
break-in-unlabeled-block-parenthesized-tttt.rs
circular_modules_hello-tttt.rs
circular_modules_main-tttt.rs
generic-param-default-in-binder-tttt.rs
issues--auxiliary--issue-94340-inc-tttt.rs
issues--circular-module-with-doc-comment-issue-97589--circular-module-with-doc-comment-issue-97589-tttt.rs
issues--circular-module-with-doc-comment-issue-97589--recursive-tttt.rs
issues--issue-48137-macros-cannot-interpolate-impl-items-bad-variants-tttt.rs
issues--issue-48137-macros-cannot-interpolate-impl-items-tttt.rs
issues--issue-48508-tttt.rs
issues--issue-5806-tttt.rs
issues--issue-65846-rollback-gating-failing-matcher-tttt.rs
issues--issue-87812-tttt.rs
macro--bad-macro-definition-tttt.rs
macro--kw-in-const-item-pos-recovery-149692-tttt.rs
macro--kw-in-item-pos-recovery-149692-tttt.rs
macro--kw-in-item-pos-recovery-151238-tttt.rs
)

# Keep fixtures that currently require a Basic AST/model change here.
# except=(
#   survive-peano-lesson-queue-tttt.rs
#   macro--issue-33569-tttt.rs
#   missing-semicolon-tttt.rs
#   anon-enums-are-ambiguous-tttt.rs
#   async-with-nonterminal-block-fttt.rs
#   attribute--attr-bad-meta-4-tttt.rs
#   attribute--attr-incomplete-tttt.rs
#   attribute--attr-unquoted-ident-tttt.rs
#   attribute--properly-recover-from-trailing-outer-attribute-in-body-2-tttt.rs
#   bad-recover-kw-after-impl-tttt.rs
#   bad-recover-ty-after-impl-tttt.rs
#   bastion-of-the-turbofish-tttt.rs
#   bounds-obj-parens-tttt.rs
#   const-block-items--attrs-tttt.rs
#   const-block-items--macro-item-tttt.rs
#   const-block-items--macro-stmt-tttt.rs
#   float-field-interpolated-tttt.rs
#   issues--issue-33418-tttt.rs
#   impl-item-const-pass-tttt.rs
#   impl-item-const-semantic-fail-tttt.rs
#   impl-item-fn-no-body-pass-tttt.rs
#   impl-item-fn-no-body-semantic-fail-tttt.rs
#   impl-item-type-no-body-pass-tttt.rs
#   impl-item-type-no-body-semantic-fail-tttt.rs
#   self-param-syntactic-pass-tttt.rs
# )

join_by_pipe() {
  local IFS='|'
  printf '%s' "$*"
}

args=(--compact-output)
# if ((${#except[@]})); then
#   args+=("--except=$(join_by_pipe "${except[@]}")")
# fi
if ((${#only[@]})); then
  args+=("--only=$(join_by_pipe "${only[@]}")")
fi

lake test -- "${args[@]}"
