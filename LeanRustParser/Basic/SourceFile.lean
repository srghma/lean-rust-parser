module

public import LeanRustParser.Basic.Mutual
public import LeanRustParser.Basic.Mutual.Repr
public import LeanRustParser.Basic.Mutual.BEq
public import LeanRustParser.Basic.Mutual.Inhabited
-- public import LeanRustParser.Basic.Mutual.Hashable
-- public import LeanRustParser.Basic.Mutual.DecidableEq

@[expose] public section

/-- A complete Rust source file. -/
structure SourceFile where
  shebang : Option String
  attrs   : List Attribute
  items   : List Item
  deriving Repr, BEq, Inhabited --, Hashable, DecidableEq
