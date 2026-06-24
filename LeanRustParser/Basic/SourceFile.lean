module

public import LeanRustParser.Basic.Mutual
public import LeanRustParser.Basic.Mutual.Repr

@[expose] public section

/-- A complete Rust source file. -/
structure SourceFile where
  shebang : Option String
  attrs   : List Attribute
  items   : List Item
  deriving Repr, DecidableEq
