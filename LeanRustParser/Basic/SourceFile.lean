module

public import LeanRustParser.Basic.Mutual
public import LeanRustParser.Basic.Mutual.Repr
public import LeanRustParser.Basic.Mutual.BEq
-- public import LeanRustParser.Basic.Mutual.Hashable
-- public import LeanRustParser.Basic.Mutual.DecidableEq

@[expose] public section

/-- A complete Rust source file. -/
structure SourceFile where -- Matches Crate in rust_ast?
  shebang : Option String
  attrs   : List Attribute
  items   : List Item
  deriving Repr, BEq --, Hashable, DecidableEq
