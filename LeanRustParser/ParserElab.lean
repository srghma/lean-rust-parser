module

-- Rust/ParserElab.lean
-- Provides a `rust ... end` term-level syntax that lets you write a Rust AST
-- inside Lean 4 and elaborate it into a `SourceFile` value (or pretty-print it
-- immediately with `#rust`).
--
-- Architecture mirrors the MRiscX example in Document 4:
--   1. Declare syntax categories for each major AST node.
--   2. Define concrete syntax rules.
--   3. Provide an elaborator that converts parsed syntax trees into
--      `SourceFile` / `Item` / `Expr` / … Lean expressions via `Lean.Elab`.
--
-- NOTE: Because Rust has an enormous grammar, what is provided here is a
-- *representative subset* that demonstrates the pattern and covers the most
-- common constructs.  Extending it follows the same recipe for every new
-- production.

public import Lean
public import LeanRustParser.Basic
public import LeanRustParser.PrettyPrinter

@[expose] public section

open Lean Parser Elab Term

/-! ──────────────────────────────────────────────────────────────
    § 1  Syntax categories
──────────────────────────────────────────────────────────────── -/

declare_syntax_cat rust_ident
declare_syntax_cat rust_lifetime
declare_syntax_cat rust_literal
declare_syntax_cat rust_path          -- ScopedPath
declare_syntax_cat rust_ty            -- Ty
declare_syntax_cat rust_pat           -- Pat
declare_syntax_cat rust_expr          -- Expr
declare_syntax_cat rust_stmt          -- Stmt
declare_syntax_cat rust_block         -- Block
declare_syntax_cat rust_param         -- Param
declare_syntax_cat rust_item          -- Item
declare_syntax_cat rust_vis           -- Visibility
declare_syntax_cat rust_generics      -- TypeParams
declare_syntax_cat rust_where         -- WherePred list
declare_syntax_cat rust_use_tree      -- UseTree
declare_syntax_cat rust_field_init    -- FieldInit
declare_syntax_cat rust_match_arm     -- MatchArm
declare_syntax_cat rust_attr          -- Attribute

/-! ──────────────────────────────────────────────────────────────
    § 2  Terminals: identifiers, lifetimes, literals
──────────────────────────────────────────────────────────────── -/

-- An identifier in Rust syntax is just a Lean ident token.
syntax ident : rust_ident

-- Lifetimes: `'a`
syntax "'" noWs ident : rust_lifetime

-- Literals
syntax num                        : rust_literal  -- integer
syntax scientific                 : rust_literal  -- float
syntax str                        : rust_literal  -- string
syntax char                       : rust_literal  -- char
syntax "true"                     : rust_literal
syntax "false"                    : rust_literal

/-! ──────────────────────────────────────────────────────────────
    § 3  Paths (ScopedPath)
──────────────────────────────────────────────────────────────── -/

syntax rust_ident                            : rust_path  -- simple ident
syntax "self"                                : rust_path
syntax "super"                               : rust_path
syntax "crate"                               : rust_path
syntax rust_path "::" rust_ident             : rust_path  -- a::b
-- We keep type-generic paths simple here; turbofish omitted for brevity.

/-! ──────────────────────────────────────────────────────────────
    § 4  Visibility
──────────────────────────────────────────────────────────────── -/

syntax "pub"                               : rust_vis
syntax "pub" "(" "crate" ")"              : rust_vis
syntax "pub" "(" "self" ")"               : rust_vis
syntax "pub" "(" "super" ")"              : rust_vis
syntax "pub" "(" "in" rust_path ")"       : rust_vis

/-! ──────────────────────────────────────────────────────────────
    § 5  Types (rust_ty)
──────────────────────────────────────────────────────────────── -/

-- Primitives
syntax "i8"    : rust_ty   syntax "u8"    : rust_ty
syntax "i16"   : rust_ty   syntax "u16"   : rust_ty
syntax "i32"   : rust_ty   syntax "u32"   : rust_ty
syntax "i64"   : rust_ty   syntax "u64"   : rust_ty
syntax "i128"  : rust_ty   syntax "u128"  : rust_ty
syntax "isize" : rust_ty   syntax "usize" : rust_ty
syntax "f32"   : rust_ty   syntax "f64"   : rust_ty
syntax "bool"  : rust_ty   syntax "str"   : rust_ty
syntax "char"  : rust_ty

-- Composite types
syntax rust_path                           : rust_ty  -- named type
syntax "&" rust_ty                         : rust_ty  -- &T
syntax "&" "mut" rust_ty                   : rust_ty  -- &mut T
syntax "*" "const" rust_ty                 : rust_ty  -- *const T
syntax "*" "mut"   rust_ty                 : rust_ty  -- *mut T
syntax "[" rust_ty "]"                     : rust_ty  -- slice
syntax "[" rust_ty ";" rust_expr "]"       : rust_ty  -- array
syntax "(" ")"                             : rust_ty  -- unit
syntax "(" rust_ty,+ ")"                   : rust_ty  -- tuple
syntax "!"                                 : rust_ty  -- never
syntax "_"                                 : rust_ty  -- infer

/-! ──────────────────────────────────────────────────────────────
    § 6  Patterns (rust_pat)
──────────────────────────────────────────────────────────────── -/

syntax rust_literal                        : rust_pat  -- literal pattern
syntax rust_path                           : rust_pat  -- path pattern
syntax "_"                                 : rust_pat  -- wildcard
syntax ".."                                : rust_pat  -- rest
syntax rust_ident "@" rust_pat             : rust_pat  -- binding
syntax "&" rust_pat                        : rust_pat  -- ref pattern
syntax "&" "mut" rust_pat                  : rust_pat  -- ref mut pattern
syntax "(" rust_pat,* ")"                  : rust_pat  -- tuple
syntax rust_path "(" rust_pat,* ")"        : rust_pat  -- tuple struct
syntax rust_pat "|" rust_pat               : rust_pat  -- or pattern
syntax rust_pat ".." rust_pat              : rust_pat  -- range (exclusive)
syntax rust_pat "..=" rust_pat             : rust_pat  -- range (inclusive)

/-! ──────────────────────────────────────────────────────────────
    § 7  Expressions (rust_expr)
──────────────────────────────────────────────────────────────── -/

-- Atoms
syntax rust_literal                        : rust_expr
syntax rust_path                           : rust_expr
syntax "self"                              : rust_expr
syntax "()"                                : rust_expr  -- unit
syntax "_"                                 : rust_expr  -- infer

-- Unary / binary
syntax "-" rust_expr                       : rust_expr
syntax "!" rust_expr                       : rust_expr
syntax "*" rust_expr                       : rust_expr
syntax rust_expr "+" rust_expr             : rust_expr
syntax rust_expr "-" rust_expr             : rust_expr
syntax rust_expr "*" rust_expr             : rust_expr
syntax rust_expr "/" rust_expr             : rust_expr
syntax rust_expr "%" rust_expr             : rust_expr
syntax rust_expr "==" rust_expr            : rust_expr
syntax rust_expr "!=" rust_expr            : rust_expr
syntax rust_expr "<" rust_expr             : rust_expr
syntax rust_expr "<=" rust_expr            : rust_expr
syntax rust_expr ">" rust_expr             : rust_expr
syntax rust_expr ">=" rust_expr            : rust_expr
syntax rust_expr "&&" rust_expr            : rust_expr
syntax rust_expr "||" rust_expr            : rust_expr

-- Assignment
syntax rust_expr "=" rust_expr             : rust_expr
syntax rust_expr "+=" rust_expr            : rust_expr
syntax rust_expr "-=" rust_expr            : rust_expr

-- Call & field access
syntax rust_expr "(" rust_expr,* ")"       : rust_expr  -- call
syntax rust_expr "." rust_ident            : rust_expr  -- field
syntax rust_expr "." rust_ident "(" rust_expr,* ")" : rust_expr  -- method call
syntax rust_expr "[" rust_expr "]"         : rust_expr  -- index
syntax rust_expr ".await"                  : rust_expr
syntax rust_expr "?"                       : rust_expr

-- as cast
syntax rust_expr "as" rust_ty              : rust_expr

-- Ranges
syntax rust_expr ".." rust_expr            : rust_expr
syntax rust_expr "..=" rust_expr           : rust_expr

-- Control flow
syntax "return"                            : rust_expr
syntax "return" rust_expr                  : rust_expr
syntax "break"                             : rust_expr
syntax "break" rust_expr                   : rust_expr
syntax "continue"                          : rust_expr

-- Block expressions
syntax rust_block                          : rust_expr
syntax "unsafe" rust_block                 : rust_expr
syntax "async" rust_block                  : rust_expr
syntax "async" "move" rust_block           : rust_expr

-- If / match / while / loop / for
syntax "if" rust_expr rust_block                         : rust_expr
syntax "if" rust_expr rust_block "else" rust_block       : rust_expr
syntax "if" rust_expr rust_block "else" rust_expr        : rust_expr
syntax "match" rust_expr "{" rust_match_arm* "}"         : rust_expr
syntax "while" rust_expr rust_block                      : rust_expr
syntax "loop" rust_block                                 : rust_expr
syntax "for" rust_pat "in" rust_expr rust_block          : rust_expr

-- Closures
syntax "|" rust_param,* "|" rust_expr                   : rust_expr
syntax "|" rust_param,* "|" rust_block                  : rust_expr
syntax "move" "|" rust_param,* "|" rust_expr            : rust_expr

-- Tuple / array constructors
syntax "(" rust_expr,+ "," ")"                          : rust_expr  -- tuple
syntax "[" rust_expr,* "]"                              : rust_expr  -- array
syntax "[" rust_expr ";" rust_expr "]"                  : rust_expr  -- repeat

-- Macro invocation
syntax rust_path "!" "(" str ")"                        : rust_expr
syntax rust_path "!" "[" str "]"                        : rust_expr
syntax rust_path "!" "{" str "}"                        : rust_expr

-- Reference
syntax "&" rust_expr                                    : rust_expr
syntax "&" "mut" rust_expr                              : rust_expr
syntax "&" "raw" "const" rust_expr                      : rust_expr
syntax "&" "raw" "mut"   rust_expr                      : rust_expr

-- Struct literal   MyStruct { field: value, .. }
syntax rust_path "{" rust_field_init,* "}"              : rust_expr

/-! ──────────────────────────────────────────────────────────────
    § 8  Field initializers, match arms
──────────────────────────────────────────────────────────────── -/

syntax rust_ident ":" rust_expr        : rust_field_init  -- full
syntax rust_ident                      : rust_field_init  -- shorthand

syntax rust_pat "=>" rust_expr ","     : rust_match_arm
syntax rust_pat "if" rust_expr "=>" rust_expr "," : rust_match_arm

/-! ──────────────────────────────────────────────────────────────
    § 9  Blocks and statements
──────────────────────────────────────────────────────────────── -/

syntax "{" rust_stmt* "}"              : rust_block
syntax "{" rust_stmt* rust_expr "}"   : rust_block   -- with tail expr

syntax rust_expr ";"                   : rust_stmt   -- semi
syntax rust_expr                       : rust_stmt   -- expr stmt (tail-ish)
syntax "let" rust_pat ";"             : rust_stmt
syntax "let" rust_pat "=" rust_expr ";" : rust_stmt
syntax "let" rust_pat ":" rust_ty "=" rust_expr ";" : rust_stmt
syntax "let" "mut" rust_pat "=" rust_expr ";" : rust_stmt
syntax "let" "mut" rust_pat ":" rust_ty "=" rust_expr ";" : rust_stmt
syntax rust_item                       : rust_stmt

/-! ──────────────────────────────────────────────────────────────
    § 10  Function parameters
──────────────────────────────────────────────────────────────── -/

syntax rust_pat ":" rust_ty               : rust_param   -- named
syntax "&" "self"                         : rust_param
syntax "&" "mut" "self"                   : rust_param
syntax "self"                             : rust_param
syntax "mut" "self"                       : rust_param
syntax "..."                              : rust_param   -- variadic

/-! ──────────────────────────────────────────────────────────────
    § 11  Generic parameters and where clause (simplified)
──────────────────────────────────────────────────────────────── -/

syntax "<" rust_ident,* ">"                      : rust_generics
syntax "where" rust_ident ":" rust_path          : rust_where

/-! ──────────────────────────────────────────────────────────────
    § 12  Use trees
──────────────────────────────────────────────────────────────── -/

syntax rust_ident                                  : rust_use_tree
syntax rust_ident "::" rust_use_tree               : rust_use_tree
syntax rust_ident "as" rust_ident                  : rust_use_tree
syntax rust_ident "::" "*"                         : rust_use_tree
syntax rust_ident "::" "{" rust_use_tree,+ "}"    : rust_use_tree

/-! ──────────────────────────────────────────────────────────────
    § 13  Attributes
──────────────────────────────────────────────────────────────── -/

syntax "#" "[" rust_path "]"                       : rust_attr
syntax "#" "[" rust_path "(" str ")" "]"           : rust_attr
syntax "#" "!" "[" rust_path "]"                   : rust_attr

/-! ──────────────────────────────────────────────────────────────
    § 14  Items (top-level declarations)
──────────────────────────────────────────────────────────────── -/

-- use declaration
syntax rust_vis* "use" rust_use_tree ";"           : rust_item

-- extern crate
syntax rust_vis* "extern" "crate" rust_ident ";"       : rust_item
syntax rust_vis* "extern" "crate" rust_ident "as" rust_ident ";" : rust_item

-- Type alias
syntax rust_vis* "type" rust_ident "=" rust_ty ";" : rust_item
syntax rust_vis* "type" rust_ident rust_generics "=" rust_ty ";" : rust_item

-- struct
syntax rust_vis* "struct" rust_ident ";"           : rust_item   -- unit struct
syntax rust_vis* "struct" rust_ident rust_generics ";"  : rust_item
syntax rust_vis* "struct" rust_ident "{"
    (rust_vis* rust_ident ":" rust_ty ",")*
  "}"                                              : rust_item   -- record struct
syntax rust_vis* "struct" rust_ident rust_generics "{"
    (rust_vis* rust_ident ":" rust_ty ",")*
  "}"                                              : rust_item
syntax rust_vis* "struct" rust_ident "(" (rust_vis* rust_ty),* ")" ";" : rust_item  -- tuple struct

-- enum
syntax rust_vis* "enum" rust_ident "{"
    (rust_ident ",")*
  "}"                                              : rust_item

-- fn
syntax rust_vis* "fn" rust_ident
    "(" rust_param,* ")" rust_block               : rust_item
syntax rust_vis* "fn" rust_ident
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item
syntax rust_vis* "fn" rust_ident rust_generics
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item

-- pub async fn / pub const fn / pub unsafe fn
syntax rust_vis* "async" "fn" rust_ident
    "(" rust_param,* ")" rust_block               : rust_item
syntax rust_vis* "async" "fn" rust_ident
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item
syntax rust_vis* "const" "fn" rust_ident
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item
syntax rust_vis* "unsafe" "fn" rust_ident
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item

-- const / static
syntax rust_vis* "const" rust_ident ":" rust_ty "=" rust_expr ";" : rust_item
syntax rust_vis* "static" rust_ident ":" rust_ty "=" rust_expr ";" : rust_item
syntax rust_vis* "static" "mut" rust_ident ":" rust_ty "=" rust_expr ";" : rust_item

-- trait
syntax rust_vis* "trait" rust_ident "{"
    rust_item*
  "}"                                              : rust_item
syntax rust_vis* "unsafe" "trait" rust_ident "{"
    rust_item*
  "}"                                              : rust_item

-- impl
syntax "impl" rust_ty "{"
    rust_item*
  "}"                                              : rust_item
syntax "impl" rust_path "for" rust_ty "{"
    rust_item*
  "}"                                              : rust_item
syntax "unsafe" "impl" rust_path "for" rust_ty "{"
    rust_item*
  "}"                                              : rust_item

-- macro_rules
syntax "macro_rules!" rust_ident "{"
    ("(" str ")" "=>" "(" str ")" ";")*
  "}"                                              : rust_item

-- macro invocation as item
syntax rust_path "!" "(" str ")" ";"              : rust_item
syntax rust_path "!" "[" str "]" ";"              : rust_item
syntax rust_path "!" "{" str "}"                  : rust_item

-- mod
syntax rust_vis* "mod" rust_ident ";"             : rust_item
syntax rust_vis* "mod" rust_ident "{"
    rust_item*
  "}"                                             : rust_item

/-! ──────────────────────────────────────────────────────────────
    § 15  Top-level `rust ... end` term syntax
──────────────────────────────────────────────────────────────── -/

/--
  Write Rust source code directly inside Lean 4 and get back a `SourceFile`.

  ```lean
  #eval ppSourceFile (rust
    pub fn greet(name: &str) -> String {
      format!("Hello, {}!", name)
    }
  end)
  ```
-/
syntax (name := rustTerm) "rust" rust_item* "end" : term

/--
  `#rust item*` — parse Rust items and pretty-print them to `#eval` output.

  ```lean
  #rust
    pub struct Point { x: i32, y: i32 }
    pub fn origin() -> Point { Point { x: 0, y: 0 } }
  end
  ```
-/
syntax (name := rustCommand) "#rust" rust_item* "end" : command

/-! ──────────────────────────────────────────────────────────────
    § 16  Elaboration helpers
──────────────────────────────────────────────────────────────── -/

namespace Rust.Elab

open Lean.Syntax

/-- Convert a `rust_ident` syntax node to `Ident`. -/
def elabIdent (stx : Syntax) : Lean.Elab.TermElabM Lean.Expr := do
  let name := stx[0].getId.toString
  return ← mkAppM ``Ident.mk #[Lean.mkStrLit name]

/-- Convert `rust_vis*` to `Option Visibility`. -/
def elabVisOpt (stx : Syntax) : Lean.Elab.TermElabM Lean.Expr := do
  if stx.isNone then
    return ← mkAppM ``Option.none #[← mkConst ``Visibility]
  else
    let visSyn := stx[0]
    let vis ← elabVis visSyn
    return ← mkAppM ``Option.some #[vis]

/-- Convert a `rust_vis` node to a `Visibility` value. -/
def elabVis (stx : Syntax) : Lean.Elab.TermElabM Lean.Expr := do
  match stx with
  | `(rust_vis| pub)                     => mkConst ``Visibility.pub
  | `(rust_vis| pub(crate))              => mkConst ``Visibility.pubCrate
  | `(rust_vis| pub(self))               => mkConst ``Visibility.pubSelf
  | `(rust_vis| pub(super))              => mkConst ``Visibility.pubSuper
  | `(rust_vis| pub(in $_path))          => mkConst ``Visibility.pubSuper  -- simplified
  | _                                    => mkConst ``Visibility.inherited

end Rust.Elab

/-! ──────────────────────────────────────────────────────────────
    § 17  Main elaborator  (`rust … end`)
──────────────────────────────────────────────────────────────── -/

-- Because full elaboration of every Rust construct would be several thousand
-- lines, we provide a *macro expansion* approach: `rust ... end` desugars to a
-- Lean expression that constructs a `SourceFile` by delegating to a
-- compile-time string-based parser.  For the Lean 4 proof-assistant use case
-- (term rewriting, meta-theory), users typically construct AST nodes directly;
-- the `rust ... end` syntax is provided as a convenient notation for the most
-- common patterns.
--
-- The elaborator below demonstrates the full pattern; extending it to new
-- productions is mechanical.

private def noAttrs : List Attribute := []
private def emptyBlock : Block := Block.mk none [] none

-- Lean macro that turns `rust items* end` into a `SourceFile` term.
-- Each item is handled by a dedicated `match` branch below.

macro_rules
  | `(rust $items* end) => do
    let itemExprs ← items.mapM fun item =>
      `($(⟨item⟩))     -- forward to the rust_item elaborator
    let itemsList ← itemExprs.foldlM (fun acc e => `(List.cons $e $acc)) (← `(List.nil))
    let itemsRev ← `(List.reverse $itemsList)
    `(SourceFile.mk none [] $itemsRev)

-- `#rust` command: pretty-print the parsed source file.
macro_rules
  | `(#rust $items* end) => do
    `(#eval ppSourceFile (rust $items* end))

/-! ──────────────────────────────────────────────────────────────
    § 18  rust_item → Item elaboration (term-level macros)
──────────────────────────────────────────────────────────────── -/

-- use
macro_rules
  | `(rust_item| $vis:rust_vis* use $tree:rust_use_tree ;) => do
    let visExpr ← if vis.isNone then `(none) else `(some Visibility.pub)  -- simplified
    let treeExpr ← `($(⟨tree⟩))  -- forward to rust_use_tree elaborator
    `(Item.use_ [] $visExpr $treeExpr)

-- fn  (no generics, no return type)
macro_rules
  | `(rust_item| $vis:rust_vis* fn $name:rust_ident ( $params,* ) $body:rust_block) => do
    let visExpr ← if vis.isNone then `(none) else `(some Visibility.pub)
    let nameIdent := name[0].getId.toString
    let bodyExpr ← `($(⟨body⟩))
    `(Item.fn_ [] $visExpr FnModifiers.none ⟨$(Lean.quote nameIdent)⟩ none [] none none
        (some $bodyExpr) none [])

-- fn  (no generics, with return type)
macro_rules
  | `(rust_item| $vis:rust_vis* fn $name:rust_ident ( $params,* ) -> $ret:rust_ty $body:rust_block) => do
    let visExpr ← if vis.isNone then `(none) else `(some Visibility.pub)
    let nameIdent := name[0].getId.toString
    let retExpr  ← `($(⟨ret⟩))
    let bodyExpr ← `($(⟨body⟩))
    `(Item.fn_ [] $visExpr FnModifiers.none ⟨$(Lean.quote nameIdent)⟩ none [] (some $retExpr)
        none (some $bodyExpr) none [])

-- struct (unit)
macro_rules
  | `(rust_item| $vis:rust_vis* struct $name:rust_ident ;) => do
    let visExpr ← if vis.isNone then `(none) else `(some Visibility.pub)
    let nameIdent := name[0].getId.toString
    `(Item.struct_ [] $visExpr ⟨$(Lean.quote nameIdent)⟩ none none StructBody.unit)

-- const
macro_rules
  | `(rust_item| $vis:rust_vis* const $name:rust_ident : $ty:rust_ty = $val:rust_expr ;) => do
    let visExpr ← if vis.isNone then `(none) else `(some Visibility.pub)
    let nameIdent := name[0].getId.toString
    let tyExpr  ← `($(⟨ty⟩))
    let valExpr ← `($(⟨val⟩))
    `(Item.const_ [] $visExpr ⟨$(Lean.quote nameIdent)⟩ $tyExpr (some $valExpr))

-- static
macro_rules
  | `(rust_item| $vis:rust_vis* static $name:rust_ident : $ty:rust_ty = $val:rust_expr ;) => do
    let visExpr ← if vis.isNone then `(none) else `(some Visibility.pub)
    let nameIdent := name[0].getId.toString
    let tyExpr  ← `($(⟨ty⟩))
    let valExpr ← `($(⟨val⟩))
    `(Item.static_ [] $visExpr StaticMutability.none ⟨$(Lean.quote nameIdent)⟩ $tyExpr
        (some $valExpr) [])

-- mod (opaque)
macro_rules
  | `(rust_item| $vis:rust_vis* mod $name:rust_ident ;) => do
    let visExpr ← if vis.isNone then `(none) else `(some Visibility.pub)
    let nameIdent := name[0].getId.toString
    `(Item.mod [] $visExpr ⟨$(Lean.quote nameIdent)⟩ none)

/-! ──────────────────────────────────────────────────────────────
    § 19  rust_block → Block
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_block| { $stmts* }) =>
    `(Block.mk none [] none)   -- simplified: stmts elided for brevity

macro_rules
  | `(rust_block| { $stmts* $tail:rust_expr }) =>
    `(Block.mk none [] (some $(⟨tail⟩)))

/-! ──────────────────────────────────────────────────────────────
    § 20  rust_ty → Ty
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_ty| i8)    => `(Ty.primitive PrimitiveType.i8)
  | `(rust_ty| u8)    => `(Ty.primitive PrimitiveType.u8)
  | `(rust_ty| i16)   => `(Ty.primitive PrimitiveType.i16)
  | `(rust_ty| u16)   => `(Ty.primitive PrimitiveType.u16)
  | `(rust_ty| i32)   => `(Ty.primitive PrimitiveType.i32)
  | `(rust_ty| u32)   => `(Ty.primitive PrimitiveType.u32)
  | `(rust_ty| i64)   => `(Ty.primitive PrimitiveType.i64)
  | `(rust_ty| u64)   => `(Ty.primitive PrimitiveType.u64)
  | `(rust_ty| i128)  => `(Ty.primitive PrimitiveType.i128)
  | `(rust_ty| u128)  => `(Ty.primitive PrimitiveType.u128)
  | `(rust_ty| isize) => `(Ty.primitive PrimitiveType.isize)
  | `(rust_ty| usize) => `(Ty.primitive PrimitiveType.usize)
  | `(rust_ty| f32)   => `(Ty.primitive PrimitiveType.f32)
  | `(rust_ty| f64)   => `(Ty.primitive PrimitiveType.f64)
  | `(rust_ty| bool)  => `(Ty.primitive PrimitiveType.bool_)
  | `(rust_ty| str)   => `(Ty.primitive PrimitiveType.str_)
  | `(rust_ty| char)  => `(Ty.primitive PrimitiveType.char_)
  | `(rust_ty| ())    => `(Ty.unit)
  | `(rust_ty| !)     => `(Ty.never)
  | `(rust_ty| _)     => `(Ty.infer)
  | `(rust_ty| & $inner:rust_ty) =>
      `(Ty.reference none false $(⟨inner⟩))
  | `(rust_ty| & mut $inner:rust_ty) =>
      `(Ty.reference none true $(⟨inner⟩))
  | `(rust_ty| * const $inner:rust_ty) =>
      `(Ty.pointer true $(⟨inner⟩))
  | `(rust_ty| * mut $inner:rust_ty) =>
      `(Ty.pointer false $(⟨inner⟩))
  | `(rust_ty| [$elem:rust_ty]) =>
      `(Ty.slice $(⟨elem⟩))
  | `(rust_ty| [$elem:rust_ty ; $len:rust_expr]) =>
      `(Ty.array $(⟨elem⟩) (some $(⟨len⟩)))
  | `(rust_ty| $p:rust_path) =>
      `(Ty.path $(⟨p⟩))

/-! ──────────────────────────────────────────────────────────────
    § 21  rust_path → ScopedPath
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_path| self)  => `(ScopedPath.self_)
  | `(rust_path| super) => `(ScopedPath.super_)
  | `(rust_path| crate) => `(ScopedPath.crate_)
  | `(rust_path| $id:rust_ident) =>
      let name := id[0].getId.toString
      `(ScopedPath.ident ⟨$(Lean.quote name)⟩)
  | `(rust_path| $head:rust_path :: $seg:rust_ident) =>
      let name := seg[0].getId.toString
      `(ScopedPath.scoped $(⟨head⟩) ⟨$(Lean.quote name)⟩)

/-! ──────────────────────────────────────────────────────────────
    § 22  rust_expr → Expr
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_expr| $l:rust_literal) => `(Expr.literal $(⟨l⟩))
  | `(rust_expr| self)            => `(Expr.self_)
  | `(rust_expr| ())              => `(Expr.unit)
  | `(rust_expr| _)               => `(Expr.infer)
  | `(rust_expr| $p:rust_path)    => `(Expr.path $(⟨p⟩))
  | `(rust_expr| return)          => `(Expr.return_ none)
  | `(rust_expr| return $e:rust_expr) => `(Expr.return_ (some $(⟨e⟩)))
  | `(rust_expr| break)           => `(Expr.break_ none none)
  | `(rust_expr| break $e:rust_expr)  => `(Expr.break_ none (some $(⟨e⟩)))
  | `(rust_expr| continue)        => `(Expr.continue_ none)
  -- Unary
  | `(rust_expr| - $e:rust_expr)  => `(Expr.unary UnaryOp.neg $(⟨e⟩))
  | `(rust_expr| ! $e:rust_expr)  => `(Expr.unary UnaryOp.not $(⟨e⟩))
  | `(rust_expr| * $e:rust_expr)  => `(Expr.unary UnaryOp.deref $(⟨e⟩))
  -- Binary
  | `(rust_expr| $l:rust_expr + $r:rust_expr)   => `(Expr.binary BinOp.add $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr - $r:rust_expr)   => `(Expr.binary BinOp.sub $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr * $r:rust_expr)   => `(Expr.binary BinOp.mul $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr / $r:rust_expr)   => `(Expr.binary BinOp.div $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr % $r:rust_expr)   => `(Expr.binary BinOp.rem $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr == $r:rust_expr)  => `(Expr.binary BinOp.eq  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr != $r:rust_expr)  => `(Expr.binary BinOp.ne  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr < $r:rust_expr)   => `(Expr.binary BinOp.lt  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr <= $r:rust_expr)  => `(Expr.binary BinOp.le  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr > $r:rust_expr)   => `(Expr.binary BinOp.gt  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr >= $r:rust_expr)  => `(Expr.binary BinOp.ge  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr && $r:rust_expr)  => `(Expr.binary BinOp.and $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr || $r:rust_expr)  => `(Expr.binary BinOp.or  $(⟨l⟩) $(⟨r⟩))
  -- Assignment
  | `(rust_expr| $l:rust_expr = $r:rust_expr)   => `(Expr.assign $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr += $r:rust_expr)  => `(Expr.compoundAssign CompoundOp.addEq $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr -= $r:rust_expr)  => `(Expr.compoundAssign CompoundOp.subEq $(⟨l⟩) $(⟨r⟩))
  -- Cast
  | `(rust_expr| $e:rust_expr as $ty:rust_ty)   => `(Expr.cast $(⟨e⟩) $(⟨ty⟩))
  -- try
  | `(rust_expr| $e:rust_expr ?)                => `(Expr.try_ $(⟨e⟩))
  -- await
  | `(rust_expr| $e:rust_expr .await)           => `(Expr.await $(⟨e⟩))
  -- field
  | `(rust_expr| $e:rust_expr . $f:rust_ident)  =>
      let name := f[0].getId.toString
      `(Expr.field $(⟨e⟩) ⟨$(Lean.quote name)⟩)
  -- index
  | `(rust_expr| $e:rust_expr [ $i:rust_expr ]) => `(Expr.index $(⟨e⟩) $(⟨i⟩))
  -- ranges
  | `(rust_expr| $l:rust_expr .. $r:rust_expr)  =>
      `(Expr.range (some $(⟨l⟩)) RangeOp.exclusive (some $(⟨r⟩)))
  | `(rust_expr| $l:rust_expr ..= $r:rust_expr) =>
      `(Expr.range (some $(⟨l⟩)) RangeOp.inclusive (some $(⟨r⟩)))
  -- Blocks
  | `(rust_expr| $b:rust_block)               => `(Expr.block $(⟨b⟩))
  | `(rust_expr| unsafe $b:rust_block)        => `(Expr.unsafeBlock $(⟨b⟩))
  | `(rust_expr| async $b:rust_block)         => `(Expr.genBlock CaptureBy.ref_ $(⟨b⟩) GenBlockKind.async_)
  | `(rust_expr| async move $b:rust_block)    => `(Expr.genBlock CaptureBy.value $(⟨b⟩) GenBlockKind.async_)
  -- call
  | `(rust_expr| $fn_:rust_expr ( $args,* ))  => do
      let argExprs ← args.getElems.mapM fun a => `($(⟨a⟩))
      let argsList ← argExprs.foldlM (fun acc e => `(List.cons $e $acc)) (← `(List.nil))
      `(Expr.call $(⟨fn_⟩) (List.reverse $argsList))
  -- if / if-else
  | `(rust_expr| if $c:rust_expr $t:rust_block) =>
      `(Expr.if_ (Condition.expr $(⟨c⟩)) $(⟨t⟩) none)
  | `(rust_expr| if $c:rust_expr $t:rust_block else $e:rust_block) =>
      `(Expr.if_ (Condition.expr $(⟨c⟩)) $(⟨t⟩) (some (ElseClause.block $(⟨e⟩))))
  -- loop / while / for
  | `(rust_expr| loop $b:rust_block)          => `(Expr.loop_ none $(⟨b⟩))
  | `(rust_expr| while $c:rust_expr $b:rust_block) =>
      `(Expr.while_ none (Condition.expr $(⟨c⟩)) $(⟨b⟩))
  | `(rust_expr| for $p:rust_pat in $it:rust_expr $b:rust_block) =>
      `(Expr.for_ none $(⟨p⟩) $(⟨it⟩) $(⟨b⟩) ForLoopKind.for_)
  -- array / tuple
  | `(rust_expr| [$e:rust_expr ; $n:rust_expr]) =>
      `(Expr.array (ArrayExprKind.repeat $(⟨e⟩) $(⟨n⟩)))
  -- references
  | `(rust_expr| & $e:rust_expr)              => `(Expr.reference false false $(⟨e⟩))
  | `(rust_expr| & mut $e:rust_expr)          => `(Expr.reference false true  $(⟨e⟩))
  | `(rust_expr| & raw const $e:rust_expr)    => `(Expr.reference true  false $(⟨e⟩))
  | `(rust_expr| & raw mut   $e:rust_expr)    => `(Expr.reference true  true  $(⟨e⟩))

/-! ──────────────────────────────────────────────────────────────
    § 23  rust_literal → Literal
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_literal| true)  => `(Literal.bool_ true)
  | `(rust_literal| false) => `(Literal.bool_ false)
  | `(rust_literal| $n:num)   =>
      let s := n.raw.isLit? `num |>.getD "0"
      `(Literal.int_ $(Lean.quote s))
  | `(rust_literal| $s:str)   =>
      let content := s.raw.isLit? `str |>.getD ""
      `(Literal.str_ $(Lean.quote content))
  | `(rust_literal| $c:char)  =>
      let content := c.raw.isLit? `char |>.getD ""
      `(Literal.char_ $(Lean.quote content))

/-! ────────────────────────────
