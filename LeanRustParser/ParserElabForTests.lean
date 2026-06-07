module

public import Lean
public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual
public import LeanRustParser.Basic.SourceFile
public import LeanRustParser.PrettyPrinter
public import LeanRustParser.ParserElab

@[expose] public section

open Lean

/-! ──────────────────────────────────────────────────────────────
    § 23  #guard_rust_ast command

    Syntax:
      #guard_rust_ast rust_item* end
      expected "..."

    Two-line form avoids ALL token conflicts:
    - "end" terminates the rust_item* sequence unambiguously
    - "expected" is a fresh keyword on a new command, not an operator
    - the strLit is the only thing after "expected"
──────────────────────────────────────────────────────────────── -/

-- Step 1: a term-level macro that takes items and builds the pp string
-- This avoids having to parse strLit in command position next to rust_item*

syntax (name := rustAstTerm) "rust_ast" rust_item* "end" : term

macro_rules
  | `(rust_ast $items* end) =>
    `(term| ppSourceFile (rust $items* end))

-- Step 2: the guard command uses Lean's built-in #guard with a term
-- Users write:
--   #guard (rust_ast async fn foo() {} end) == "async fn foo() {\n}"
-- This is valid because #guard takes a plain term, and "==" in a term
-- is fine — it's only in *command* syntax declarations that "==" conflicts.

-- Expose rust_ast so test files can write:
--   #guard (rust_ast fn foo() {} end) == "fn foo() {\n}"

