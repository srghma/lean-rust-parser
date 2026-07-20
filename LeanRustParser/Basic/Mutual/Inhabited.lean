module

public import LeanRustParser.Basic.Mutual

@[expose] public section

/-! This module intentionally provides no blanket `Inhabited` instances for
the mutually recursive source AST.

`rustc_ast` has no canonical default for nodes such as `Expr`, `Ty`, or `Item`.
An arbitrary recursive default would invent source or recovery syntax and make
`default` look meaningful to parser and printer code.  Consumers must instead
construct the node required by the grammar. -/
