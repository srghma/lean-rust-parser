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

public import Lean
public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual
public import LeanRustParser.Basic.SourceFile

@[expose] public section

open Lean

/-! ──────────────────────────────────────────────────────────────
    § 1  Syntax categories
──────────────────────────────────────────────────────────────── -/

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
    § 2  Terminals: lifetimes, literals
──────────────────────────────────────────────────────────────── -/

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

syntax ident                                 : rust_path  -- simple ident
syntax "self"                                : rust_path
syntax "super"                               : rust_path
syntax "crate"                               : rust_path
syntax rust_path "::" ident                  : rust_path  -- a::b

/-! ──────────────────────────────────────────────────────────────
    § 4  Visibility
──────────────────────────────────────────────────────────────── -/

syntax "pub"                               : rust_vis
syntax "pub" "(" "crate" ")"               : rust_vis
syntax "pub" "(" "self" ")"                : rust_vis
syntax "pub" "(" "super" ")"               : rust_vis
syntax "pub" "(" "in" rust_path ")"        : rust_vis

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
syntax "()"                                : rust_ty  -- unit
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
syntax ident "@" rust_pat                  : rust_pat  -- binding
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
syntax rust_expr "." ident                 : rust_expr  -- field
syntax (priority := high) rust_expr "." ident "(" rust_expr,* ")" : rust_expr  -- method call
syntax rust_expr "[" rust_expr "]"         : rust_expr  -- index
syntax rust_expr "." "await"               : rust_expr
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
syntax "if" rust_expr rust_block "else" rust_expr        : rust_expr
syntax "match" rust_expr "{" rust_match_arm* "}"         : rust_expr
syntax "while" rust_expr rust_block                      : rust_expr
syntax "loop" rust_block                                 : rust_expr
syntax "for" rust_pat "in" rust_expr rust_block          : rust_expr

-- Closures
syntax "|" rust_param,* "|" rust_expr                   : rust_expr
syntax "move" "|" rust_param,* "|" rust_expr            : rust_expr

-- Tuple / array constructors
syntax "(" rust_expr,+ "," ")"                          : rust_expr  -- tuple
syntax "[" rust_expr,* "]"                              : rust_expr  -- array
syntax "[" rust_expr ";" rust_expr "]"                  : rust_expr  -- repeat

-- Macro invocation
syntax rust_path "!" "(" rust_literal ")"               : rust_expr
syntax rust_path "!" "[" rust_literal "]"               : rust_expr
syntax rust_path "!" "{" rust_literal "}"               : rust_expr

-- Reference
syntax "&" rust_expr                                    : rust_expr
syntax "&" "mut" rust_expr                              : rust_expr
syntax "&" "raw" "const" rust_expr                      : rust_expr
syntax "&" "raw" "mut"   rust_expr                      : rust_expr

-- Struct literal
syntax rust_path "{" rust_field_init,* "}"              : rust_expr

/-! ──────────────────────────────────────────────────────────────
    § 8  Field initializers, match arms
──────────────────────────────────────────────────────────────── -/

syntax ident ":" rust_expr             : rust_field_init  -- full
syntax ident                           : rust_field_init  -- shorthand

syntax rust_pat "=>" rust_expr ","     : rust_match_arm
syntax rust_pat "if" rust_expr "=>" rust_expr "," : rust_match_arm

/-! ──────────────────────────────────────────────────────────────
    § 9  Blocks and statements
──────────────────────────────────────────────────────────────── -/

syntax "{" rust_stmt* "}"              : rust_block
syntax "{" rust_stmt* rust_expr "}"    : rust_block   -- with tail expr

syntax rust_expr ";"                   : rust_stmt   -- semi
syntax rust_expr                       : rust_stmt   -- expr stmt
syntax "let" rust_pat ";"              : rust_stmt
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

syntax "<" ident,* ">"                           : rust_generics
syntax "where" ident ":" rust_path               : rust_where

/-! ──────────────────────────────────────────────────────────────
    § 12  Use trees
──────────────────────────────────────────────────────────────── -/

syntax ident                                       : rust_use_tree
syntax ident "::" rust_use_tree                    : rust_use_tree
syntax ident "as" ident                            : rust_use_tree
syntax ident "::" "*"                              : rust_use_tree
syntax ident "::" "{" rust_use_tree,+ "}"          : rust_use_tree

/-! ──────────────────────────────────────────────────────────────
    § 13  Attributes
──────────────────────────────────────────────────────────────── -/

syntax "#" "[" rust_path "]"                       : rust_attr
syntax "#" "[" rust_path "(" rust_literal ")" "]"  : rust_attr
syntax "#" "!" "[" rust_path "]"                   : rust_attr

/-! ──────────────────────────────────────────────────────────────
    § 14  Items (top-level declarations)
──────────────────────────────────────────────────────────────── -/

-- use declaration
syntax rust_vis* "use" rust_use_tree ";"           : rust_item

-- extern crate
syntax rust_vis* "extern" "crate" ident ";"        : rust_item
syntax rust_vis* "extern" "crate" ident "as" ident ";" : rust_item

-- Type alias
syntax rust_vis* "type" ident "=" rust_ty ";"      : rust_item
syntax rust_vis* "type" ident rust_generics "=" rust_ty ";" : rust_item

-- struct
syntax rust_vis* "struct" ident ";"                : rust_item   -- unit struct
syntax rust_vis* "struct" ident rust_generics ";"  : rust_item
syntax rust_vis* "struct" ident "{"
    (rust_vis* ident ":" rust_ty ",")*
  "}"                                              : rust_item   -- record struct
syntax rust_vis* "struct" ident rust_generics "{"
    (rust_vis* ident ":" rust_ty ",")*
  "}"                                              : rust_item
syntax rust_vis* "struct" ident "(" (rust_vis* rust_ty),* ")" ";" : rust_item

-- enum
syntax rust_vis* "enum" ident "{"
    (ident ",")*
  "}"                                              : rust_item

-- fn
syntax rust_vis* "fn" ident
    "(" rust_param,* ")" rust_block               : rust_item
syntax rust_vis* "fn" ident
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item
syntax rust_vis* "fn" ident rust_generics
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item

-- pub async fn / pub const fn / pub unsafe fn
syntax rust_vis* "async" "fn" ident
    "(" rust_param,* ")" rust_block               : rust_item
syntax rust_vis* "async" "fn" ident
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item
syntax rust_vis* "const" "fn" ident
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item
syntax rust_vis* "unsafe" "fn" ident
    "(" rust_param,* ")" "->" rust_ty rust_block  : rust_item

-- const / static
syntax rust_vis* "const" ident ":" rust_ty "=" rust_expr ";" : rust_item
syntax rust_vis* "static" ident ":" rust_ty "=" rust_expr ";" : rust_item
syntax rust_vis* "static" "mut" ident ":" rust_ty "=" rust_expr ";" : rust_item

-- trait
syntax rust_vis* "trait" ident "{"
    rust_item*
  "}"                                              : rust_item
syntax rust_vis* "unsafe" "trait" ident "{"
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
syntax "macro_rules!" ident "{"
    ("(" rust_literal ")" "=>" "(" rust_literal ")" ";")*
  "}"                                              : rust_item

-- macro invocation as item
syntax rust_path "!" "(" rust_literal ")" ";"      : rust_item
syntax rust_path "!" "[" rust_literal "]" ";"      : rust_item
syntax rust_path "!" "{" rust_literal "}"          : rust_item

-- mod
syntax rust_vis* "mod" ident ";"                  : rust_item
syntax rust_vis* "mod" ident "{"
    rust_item*
  "}"                                             : rust_item

/-! ──────────────────────────────────────────────────────────────
    § 15  Top-level `rust ... end` term syntax
──────────────────────────────────────────────────────────────── -/

syntax (name := rustTerm) "rust" rust_item* "end" : term

syntax (name := rustCommand) "#rust" rust_item* "end" : command

/-! ──────────────────────────────────────────────────────────────
    § 16  Main elaborator  (`rust … end`)
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust $items* end) => do
    let itemExprs ← items.mapM fun item =>
      `(term| $(⟨item⟩))
    let itemsList ← itemExprs.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    let itemsRev ← `(term| List.reverse $itemsList)
    `(term| SourceFile.mk Option.none [] $itemsRev)

macro_rules
  | `(#rust $items* end) => do
    `(#eval ppSourceFile (rust $items* end))

/-! ──────────────────────────────────────────────────────────────
    § 17  rust_item → Item elaboration (term-level macros)
──────────────────────────────────────────────────────────────── -/

-- use
macro_rules
  | `(rust_item| $vis:rust_vis* use $tree:rust_use_tree ;) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let treeExpr ← `(term| $(⟨tree⟩))
    `(term| Item.use_ [] $visExpr $treeExpr)

-- fn (no return type)
macro_rules
  | `(rust_item| $vis:rust_vis* fn $name:ident ( $_params,* ) $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr FnModifiers.none (Ident.mk $(Lean.quote nameIdent)) Option.none [] Option.none Option.none (Option.some $bodyExpr) Option.none [])

-- fn (with return type)
macro_rules
  | `(rust_item| $vis:rust_vis* fn $name:ident ( $_params,* ) -> $ret:rust_ty $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let retExpr  ← `(term| $(⟨ret⟩))
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr FnModifiers.none (Ident.mk $(Lean.quote nameIdent)) Option.none [] (Option.some $retExpr) Option.none (Option.some $bodyExpr) Option.none [])

-- struct (unit)
macro_rules
  | `(rust_item| $vis:rust_vis* struct $name:ident ;) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    `(term| Item.struct_ [] $visExpr (Ident.mk $(Lean.quote nameIdent)) Option.none Option.none StructBody.unit)

-- const
macro_rules
  | `(rust_item| $vis:rust_vis* const $name:ident : $ty:rust_ty = $val:rust_expr ;) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let tyExpr  ← `(term| $(⟨ty⟩))
    let valExpr ← `(term| $(⟨val⟩))
    `(term| Item.const_ [] $visExpr (Ident.mk $(Lean.quote nameIdent)) $tyExpr (Option.some $valExpr))

-- static
macro_rules
  | `(rust_item| $vis:rust_vis* static $name:ident : $ty:rust_ty = $val:rust_expr ;) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let tyExpr  ← `(term| $(⟨ty⟩))
    let valExpr ← `(term| $(⟨val⟩))
    `(term| Item.static_ [] $visExpr Bool.false (Ident.mk $(Lean.quote nameIdent)) $tyExpr (Option.some $valExpr) [])

-- mod (opaque)
macro_rules
  | `(rust_item| $vis:rust_vis* mod $name:ident ;) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    `(term| Item.mod [] $visExpr (Ident.mk $(Lean.quote nameIdent)) Option.none)

/-! ──────────────────────────────────────────────────────────────
    § 18  rust_block → Block
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_block| { $_stmts:rust_stmt* }) =>
    `(term| Block.mk Option.none [] Option.none)

macro_rules
  | `(rust_block| { $_stmts:rust_stmt* $tail:rust_expr }) =>
    `(term| Block.mk Option.none [] (Option.some $(⟨tail⟩)))

/-! ──────────────────────────────────────────────────────────────
    § 19  rust_ty → Ty
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_ty| i8)    => `(term| Ty.primitive PrimitiveType.i8)
  | `(rust_ty| u8)    => `(term| Ty.primitive PrimitiveType.u8)
  | `(rust_ty| i16)   => `(term| Ty.primitive PrimitiveType.i16)
  | `(rust_ty| u16)   => `(term| Ty.primitive PrimitiveType.u16)
  | `(rust_ty| i32)   => `(term| Ty.primitive PrimitiveType.i32)
  | `(rust_ty| u32)   => `(term| Ty.primitive PrimitiveType.u32)
  | `(rust_ty| i64)   => `(term| Ty.primitive PrimitiveType.i64)
  | `(rust_ty| u64)   => `(term| Ty.primitive PrimitiveType.u64)
  | `(rust_ty| i128)  => `(term| Ty.primitive PrimitiveType.i128)
  | `(rust_ty| u128)  => `(term| Ty.primitive PrimitiveType.u128)
  | `(rust_ty| isize) => `(term| Ty.primitive PrimitiveType.isize)
  | `(rust_ty| usize) => `(term| Ty.primitive PrimitiveType.usize)
  | `(rust_ty| f32)   => `(term| Ty.primitive PrimitiveType.f32)
  | `(rust_ty| f64)   => `(term| Ty.primitive PrimitiveType.f64)
  | `(rust_ty| bool)  => `(term| Ty.primitive PrimitiveType.bool_)
  | `(rust_ty| str)   => `(term| Ty.primitive PrimitiveType.str_)
  | `(rust_ty| char)  => `(term| Ty.primitive PrimitiveType.char_)
  | `(rust_ty| ())    => `(term| Ty.unit)
  | `(rust_ty| !)     => `(term| Ty.never)
  | `(rust_ty| _)     => `(term| Ty.infer)
  | `(rust_ty| & $inner:rust_ty) =>
      `(term| Ty.reference Option.none Bool.false $(⟨inner⟩))
  | `(rust_ty| & mut $inner:rust_ty) =>
      `(term| Ty.reference Option.none Bool.true $(⟨inner⟩))
  | `(rust_ty| * const $inner:rust_ty) =>
      `(term| Ty.pointer Bool.true $(⟨inner⟩))
  | `(rust_ty| * mut $inner:rust_ty) =>
      `(term| Ty.pointer Bool.false $(⟨inner⟩))
  | `(rust_ty| [$elem:rust_ty]) =>
      `(term| Ty.slice $(⟨elem⟩))
  | `(rust_ty| [$elem:rust_ty ; $len:rust_expr]) =>
      `(term| Ty.array $(⟨elem⟩) (Option.some $(⟨len⟩)))
  | `(rust_ty| $p:rust_path) =>
      `(term| Ty.path $(⟨p⟩))

/-! ──────────────────────────────────────────────────────────────
    § 20  rust_path → ScopedPath
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_path| self)  => `(term| ScopedPath.self_)
  | `(rust_path| super) => `(term| ScopedPath.super_)
  | `(rust_path| crate) => `(term| ScopedPath.crate_)
  | `(rust_path| $id:ident) => do
      let name := id.getId.toString
      `(term| ScopedPath.ident (Ident.mk $(Lean.quote name)))
  | `(rust_path| $head:rust_path :: $seg:ident) => do
      let name := seg.getId.toString
      `(term| ScopedPath.scoped $(⟨head⟩) (Ident.mk $(Lean.quote name)))

/-! ──────────────────────────────────────────────────────────────
    § 21  rust_expr → Expr
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_expr| $l:rust_literal) => `(term| Expr.literal $(⟨l⟩))
  | `(rust_expr| ())              => `(term| Expr.unit)
  | `(rust_expr| _)               => `(term| Expr.infer)
  | `(rust_expr| $p:rust_path)    => `(term| Expr.path $(⟨p⟩))
  | `(rust_expr| return)          => `(term| Expr.return_ Option.none)
  | `(rust_expr| return $e:rust_expr) => `(term| Expr.return_ (Option.some $(⟨e⟩)))
  | `(rust_expr| break)           => `(term| Expr.break_ Option.none Option.none)
  | `(rust_expr| break $e:rust_expr)  => `(term| Expr.break_ Option.none (Option.some $(⟨e⟩)))
  | `(rust_expr| continue)        => `(term| Expr.continue_ Option.none)
  -- Unary
  | `(rust_expr| - $e:rust_expr)  => `(term| Expr.unary UnaryOp.neg $(⟨e⟩))
  | `(rust_expr| ! $e:rust_expr)  => `(term| Expr.unary UnaryOp.not $(⟨e⟩))
  | `(rust_expr| * $e:rust_expr)  => `(term| Expr.unary UnaryOp.deref $(⟨e⟩))
  -- Binary
  | `(rust_expr| $l:rust_expr + $r:rust_expr)   => `(term| Expr.binary BinOp.add $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr - $r:rust_expr)   => `(term| Expr.binary BinOp.sub $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr * $r:rust_expr)   => `(term| Expr.binary BinOp.mul $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr / $r:rust_expr)   => `(term| Expr.binary BinOp.div $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr % $r:rust_expr)   => `(term| Expr.binary BinOp.rem $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr == $r:rust_expr)  => `(term| Expr.binary BinOp.eq  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr != $r:rust_expr)  => `(term| Expr.binary BinOp.ne  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr < $r:rust_expr)   => `(term| Expr.binary BinOp.lt  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr <= $r:rust_expr)  => `(term| Expr.binary BinOp.le  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr > $r:rust_expr)   => `(term| Expr.binary BinOp.gt  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr >= $r:rust_expr)  => `(term| Expr.binary BinOp.ge  $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr && $r:rust_expr)  => `(term| Expr.binary BinOp.and $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr || $r:rust_expr)  => `(term| Expr.binary BinOp.or  $(⟨l⟩) $(⟨r⟩))
  -- Assignment
  | `(rust_expr| $l:rust_expr = $r:rust_expr)   => `(term| Expr.assign $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr += $r:rust_expr)  => `(term| Expr.compoundAssign CompoundOp.addEq $(⟨l⟩) $(⟨r⟩))
  | `(rust_expr| $l:rust_expr -= $r:rust_expr)  => `(term| Expr.compoundAssign CompoundOp.subEq $(⟨l⟩) $(⟨r⟩))
  -- Cast
  | `(rust_expr| $e:rust_expr as $ty:rust_ty)   => `(term| Expr.cast $(⟨e⟩) $(⟨ty⟩))
  -- try
  | `(rust_expr| $e:rust_expr ?)                => `(term| Expr.try_ $(⟨e⟩))
  -- await
  | `(rust_expr| $e:rust_expr . await)          => `(term| Expr.await $(⟨e⟩))
  -- field
  | `(rust_expr| $e:rust_expr . $f:ident)  => do
      let name := f.getId.toString
      `(term| Expr.field $(⟨e⟩) (Ident.mk $(Lean.quote name)))
  -- index
  | `(rust_expr| $e:rust_expr [ $i:rust_expr ]) => `(term| Expr.index $(⟨e⟩) $(⟨i⟩))
  -- ranges
  | `(rust_expr| $l:rust_expr .. $r:rust_expr)  =>
      `(term| Expr.range (Option.some $(⟨l⟩)) RangeOp.exclusive (Option.some $(⟨r⟩)))
  | `(rust_expr| $l:rust_expr ..= $r:rust_expr) =>
      `(term| Expr.range (Option.some $(⟨l⟩)) RangeOp.inclusive (Option.some $(⟨r⟩)))
  -- Blocks
  | `(rust_expr| $b:rust_block)               => `(term| Expr.block $(⟨b⟩))
  | `(rust_expr| unsafe $b:rust_block)        => `(term| Expr.unsafeBlock $(⟨b⟩))
  | `(rust_expr| async $b:rust_block)         => `(term| Expr.genBlock CaptureBy.ref_ $(⟨b⟩) GenBlockKind.async_)
  | `(rust_expr| async move $b:rust_block)    => `(term| Expr.genBlock CaptureBy.value $(⟨b⟩) GenBlockKind.async_)
  -- call
  | `(rust_expr| $fn_:rust_expr ( $args,* ))  => do
      let argExprs ← args.getElems.mapM fun a => `(term| $(⟨a⟩))
      let argsList ← argExprs.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
      `(term| Expr.call $(⟨fn_⟩) (List.reverse $argsList))
  -- if / if-else
  | `(rust_expr| if $c:rust_expr $t:rust_block) =>
      `(term| Expr.if_ (Condition.expr $(⟨c⟩)) $(⟨t⟩) Option.none)
  | `(rust_expr| if $c:rust_expr $t:rust_block else $e:rust_expr) =>
      `(term| Expr.if_ (Condition.expr $(⟨c⟩)) $(⟨t⟩) (Option.some (ElseClause.elseIf $(⟨e⟩))))
  -- loop / while / for
  | `(rust_expr| loop $b:rust_block)          => `(term| Expr.loop_ Option.none $(⟨b⟩))
  | `(rust_expr| while $c:rust_expr $b:rust_block) =>
      `(term| Expr.while_ Option.none (Condition.expr $(⟨c⟩)) $(⟨b⟩))
  | `(rust_expr| for $p:rust_pat in $it:rust_expr $b:rust_block) =>
      `(term| Expr.for_ Option.none $(⟨p⟩) $(⟨it⟩) $(⟨b⟩) ForLoopKind.for_)
  -- array / tuple
  | `(rust_expr| [$e:rust_expr ; $n:rust_expr]) =>
      `(term| Expr.array (ArrayExprKind.repeat $(⟨e⟩) $(⟨n⟩)))
  -- references
  | `(rust_expr| & $e:rust_expr)              => `(term| Expr.reference Bool.false Bool.false $(⟨e⟩))
  | `(rust_expr| & mut $e:rust_expr)          => `(term| Expr.reference Bool.false Bool.true  $(⟨e⟩))
  | `(rust_expr| & raw const $e:rust_expr)    => `(term| Expr.reference Bool.true  Bool.false $(⟨e⟩))
  | `(rust_expr| & raw mut   $e:rust_expr)    => `(term| Expr.reference Bool.true  Bool.true  $(⟨e⟩))

/-! ──────────────────────────────────────────────────────────────
    § 22  rust_literal → Literal
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_literal| true)  => `(term| Literal.bool_ Bool.true)
  | `(rust_literal| false) => `(term| Literal.bool_ Bool.false)
  | `(rust_literal| $n:num)   => do
      let s := toString n.getNat
      `(term| Literal.int_ $(Lean.quote s))
  | `(rust_literal| $s:str)   => do
      let content := s.getString
      `(term| Literal.str_ $(Lean.quote content))
  | `(rust_literal| $c:char)  => do
      let content := toString c.getChar
      `(term| Literal.char_ $(Lean.quote content))

-- #guard_rust_ast is defined in ParserElabForTests.lean which imports this file.
-- The syntax declaration lives there to avoid the "==" token conflict
-- in command position when declared alongside rust_item* parsing.

/-! ──────────────────────────────────────────────────────────────
    § 24  rust_stmt → Stmt elaboration
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_stmt| $e:rust_expr ;) =>
    `(term| Stmt.semi $(⟨e⟩))
  | `(rust_stmt| $e:rust_expr) =>
    `(term| Stmt.expr $(⟨e⟩))
  | `(rust_stmt| let $p:rust_pat ;) =>
    `(term| Stmt.let_ Bool.false $(⟨p⟩) Option.none Option.none Option.none)
  | `(rust_stmt| let $p:rust_pat = $v:rust_expr ;) =>
    `(term| Stmt.let_ Bool.false $(⟨p⟩) Option.none (Option.some $(⟨v⟩)) Option.none)
  | `(rust_stmt| let $p:rust_pat : $t:rust_ty = $v:rust_expr ;) =>
    `(term| Stmt.let_ Bool.false $(⟨p⟩) (Option.some $(⟨t⟩)) (Option.some $(⟨v⟩)) Option.none)
  | `(rust_stmt| let mut $p:rust_pat = $v:rust_expr ;) =>
    `(term| Stmt.let_ Bool.true $(⟨p⟩) Option.none (Option.some $(⟨v⟩)) Option.none)
  | `(rust_stmt| let mut $p:rust_pat : $t:rust_ty = $v:rust_expr ;) =>
    `(term| Stmt.let_ Bool.true $(⟨p⟩) (Option.some $(⟨t⟩)) (Option.some $(⟨v⟩)) Option.none)
  | `(rust_stmt| $it:rust_item) =>
    `(term| Stmt.item $(⟨it⟩))

/-! ──────────────────────────────────────────────────────────────
    § 25  rust_pat → Pat elaboration
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_pat| $l:rust_literal) =>
    `(term| Pat.literal $(⟨l⟩))
  | `(rust_pat| _) =>
    `(term| Pat.wildcard)
  | `(rust_pat| ..) =>
    `(term| Pat.rest)
  | `(rust_pat| $id:ident @ $p:rust_pat) => do
    let name := id.getId.toString
    `(term| Pat.ident Bool.false Bool.false (Ident.mk $(Lean.quote name)) (Option.some $(⟨p⟩)))
  | `(rust_pat| & mut $p:rust_pat) =>
    `(term| Pat.reference Bool.true $(⟨p⟩))
  | `(rust_pat| & $p:rust_pat) =>
    `(term| Pat.reference Bool.false $(⟨p⟩))
  | `(rust_pat| ( $ps,* )) => do
    let elems ← ps.getElems.mapM fun p => `(term| $(⟨p⟩))
    let lst ← elems.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    `(term| Pat.tuple (List.reverse $lst))
  | `(rust_pat| $p1:rust_pat | $p2:rust_pat) =>
    `(term| Pat.or [$(⟨p1⟩), $(⟨p2⟩)])
  | `(rust_pat| $lo:rust_pat .. $hi:rust_pat) =>
    `(term| Pat.range (Option.some (RangePat.path $(⟨lo⟩))) RangeOp.exclusive
            (Option.some (RangePat.path $(⟨hi⟩))))
  | `(rust_pat| $path:rust_path ( $ps,* )) => do
    let elems ← ps.getElems.mapM fun p => `(term| $(⟨p⟩))
    let lst ← elems.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    `(term| Pat.tupleStruct $(⟨path⟩) (List.reverse $lst))
  | `(rust_pat| $p:rust_path) =>
    `(term| Pat.path $(⟨p⟩))

/-! ──────────────────────────────────────────────────────────────
    § 26  rust_param → Param elaboration
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_param| & self) =>
    `(term| Param.self_ Bool.true Option.none Bool.false)
  | `(rust_param| & mut self) =>
    `(term| Param.self_ Bool.true Option.none Bool.true)
  | `(rust_param| self) =>
    `(term| Param.self_ Bool.false Option.none Bool.false)
  | `(rust_param| mut self) =>
    `(term| Param.self_ Bool.false Option.none Bool.true)
  | `(rust_param| ...) =>
    `(term| Param.variadic Option.none)
  | `(rust_param| $p:rust_pat : $t:rust_ty) =>
    `(term| Param.named Bool.false $(⟨p⟩) $(⟨t⟩))

/-! ──────────────────────────────────────────────────────────────
    § 27  rust_use_tree → UseTree elaboration
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_use_tree| $id:ident) => do
    let name := id.getId.toString
    `(term| UseTree.name (Ident.mk $(Lean.quote name)))
  | `(rust_use_tree| $id:ident :: $child:rust_use_tree) => do
    let name := id.getId.toString
    `(term| UseTree.path (Ident.mk $(Lean.quote name)) $(⟨child⟩))
  | `(rust_use_tree| $id:ident as $alias:ident) => do
    let name  := id.getId.toString
    let aname := alias.getId.toString
    `(term| UseTree.alias (Ident.mk $(Lean.quote name)) (Ident.mk $(Lean.quote aname)))
  | `(rust_use_tree| $id:ident :: *) => do
    let name := id.getId.toString
    `(term| UseTree.path (Ident.mk $(Lean.quote name)) UseTree.glob)
  | `(rust_use_tree| $id:ident :: { $ts,* }) => do
    let name := id.getId.toString
    let elems ← ts.getElems.mapM fun t => `(term| $(⟨t⟩))
    let lst ← elems.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    `(term| UseTree.path (Ident.mk $(Lean.quote name)) (UseTree.list (List.reverse $lst)))

/-! ──────────────────────────────────────────────────────────────
    § 28  rust_field_init → FieldInit elaboration
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_field_init| $id:ident : $e:rust_expr) => do
    let name := id.getId.toString
    `(term| FieldInit.full (Ident.mk $(Lean.quote name)) $(⟨e⟩))
  | `(rust_field_init| $id:ident) => do
    let name := id.getId.toString
    `(term| FieldInit.shorthand (Ident.mk $(Lean.quote name)))

/-! ──────────────────────────────────────────────────────────────
    § 29  rust_match_arm → MatchArm elaboration
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_match_arm| $p:rust_pat => $e:rust_expr ,) =>
    `(term| MatchArm.mk [] $(⟨p⟩) Option.none $(⟨e⟩))
  | `(rust_match_arm| $p:rust_pat if $g:rust_expr => $e:rust_expr ,) =>
    `(term| MatchArm.mk [] $(⟨p⟩) (Option.some (Condition.expr $(⟨g⟩))) $(⟨e⟩))

/-! ──────────────────────────────────────────────────────────────
    § 30  rust_expr: macro invocation elaboration
──────────────────────────────────────────────────────────────── -/

macro_rules
  | `(rust_expr| $p:rust_path ! ( $lit:rust_literal )) =>
    `(term| Expr.macro_ (MacroInvocation.mk $(⟨p⟩) (TokenTree.parens (ppLiteral $(⟨lit⟩) |>.render 0))))
  | `(rust_expr| $p:rust_path ! [ $lit:rust_literal ]) =>
    `(term| Expr.macro_ (MacroInvocation.mk $(⟨p⟩) (TokenTree.brackets (ppLiteral $(⟨lit⟩) |>.render 0))))
  | `(rust_expr| $p:rust_path ! { $lit:rust_literal }) =>
    `(term| Expr.macro_ (MacroInvocation.mk $(⟨p⟩) (TokenTree.braces (ppLiteral $(⟨lit⟩) |>.render 0))))

/-! ──────────────────────────────────────────────────────────────
    § 31  rust_item: async/const/unsafe fn elaboration
──────────────────────────────────────────────────────────────── -/

-- async fn (no return type)
macro_rules
  | `(rust_item| $vis:rust_vis* async fn $name:ident ( $params,* ) $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let paramExprs ← params.getElems.mapM fun p => `(term| $(⟨p⟩))
    let paramsList ← paramExprs.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr
        (FnModifiers.mods (Option.some GenBlockKind.async_) Bool.false Bool.false Bool.false Option.none)
        (Ident.mk $(Lean.quote nameIdent))
        Option.none (List.reverse $paramsList) Option.none Option.none
        (Option.some $bodyExpr) Option.none [])

-- async fn (with return type)
macro_rules
  | `(rust_item| $vis:rust_vis* async fn $name:ident ( $params,* ) -> $ret:rust_ty $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let paramExprs ← params.getElems.mapM fun p => `(term| $(⟨p⟩))
    let paramsList ← paramExprs.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    let retExpr ← `(term| $(⟨ret⟩))
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr
        (FnModifiers.mods (Option.some GenBlockKind.async_) Bool.false Bool.false Bool.false Option.none)
        (Ident.mk $(Lean.quote nameIdent))
        Option.none (List.reverse $paramsList) (Option.some $retExpr) Option.none
        (Option.some $bodyExpr) Option.none [])

-- const fn (with return type)
macro_rules
  | `(rust_item| $vis:rust_vis* const fn $name:ident ( $params,* ) -> $ret:rust_ty $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let paramExprs ← params.getElems.mapM fun p => `(term| $(⟨p⟩))
    let paramsList ← paramExprs.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    let retExpr ← `(term| $(⟨ret⟩))
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr
        (FnModifiers.mods Option.none Bool.true Bool.false Bool.false Option.none)
        (Ident.mk $(Lean.quote nameIdent))
        Option.none (List.reverse $paramsList) (Option.some $retExpr) Option.none
        (Option.some $bodyExpr) Option.none [])

-- unsafe fn (with return type)
macro_rules
  | `(rust_item| $vis:rust_vis* unsafe fn $name:ident ( $params,* ) -> $ret:rust_ty $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let paramExprs ← params.getElems.mapM fun p => `(term| $(⟨p⟩))
    let paramsList ← paramExprs.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    let retExpr ← `(term| $(⟨ret⟩))
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr
        (FnModifiers.mods Option.none Bool.false Bool.true Bool.false Option.none)
        (Ident.mk $(Lean.quote nameIdent))
        Option.none (List.reverse $paramsList) (Option.some $retExpr) Option.none
        (Option.some $bodyExpr) Option.none [])

/-! ──────────────────────────────────────────────────────────────
    § 32  rust_block: fix to elaborate statements
──────────────────────────────────────────────────────────────── -/

-- Override the simplified block elaborators with ones that handle stmts.
-- These must come AFTER the earlier definitions; macro_rules adds alternatives
-- checked in reverse order (last wins for same pattern), but since the
-- pattern is identical we use a priority trick: put these in a separate
-- macro_rules that shadows the earlier ones.

-- Note: Lean picks the LAST matching macro_rules alternative, so these
-- definitions below will take priority over the stubs in § 18.

macro_rules
  | `(rust_block| { $stmts:rust_stmt* }) => do
    let stmtExprs ← stmts.mapM fun s => `(term| $(⟨s⟩))
    let stmtsList ← stmtExprs.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    `(term| Block.mk Option.none (List.reverse $stmtsList) Option.none)

macro_rules
  | `(rust_block| { $stmts:rust_stmt* $tail:rust_expr }) => do
    let stmtExprs ← stmts.mapM fun s => `(term| $(⟨s⟩))
    let stmtsList ← stmtExprs.foldlM (fun acc e => `(term| List.cons $e $acc)) (← `(term| List.nil))
    `(term| Block.mk Option.none (List.reverse $stmtsList) (Option.some $(⟨tail⟩)))

-- fn with zero params (priority fix: `()` would otherwise be parsed as rust_ty/rust_expr)
syntax (priority := high) rust_vis* "fn" ident
    "()" rust_block                               : rust_item
syntax (priority := high) rust_vis* "fn" ident
    "()" "->" rust_ty rust_block                  : rust_item
syntax (priority := high) rust_vis* "async" "fn" ident
    "()" rust_block                               : rust_item
syntax (priority := high) rust_vis* "async" "fn" ident
    "()" "->" rust_ty rust_block                  : rust_item
syntax (priority := high) rust_vis* "const" "fn" ident
    "()" "->" rust_ty rust_block                  : rust_item
syntax (priority := high) rust_vis* "unsafe" "fn" ident
    "()" "->" rust_ty rust_block                  : rust_item

-- fn zero params, no return type
macro_rules
  | `(rust_item| $vis:rust_vis* fn $name:ident () $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr FnModifiers.none
        (Ident.mk $(Lean.quote nameIdent)) Option.none [] Option.none Option.none
        (Option.some $bodyExpr) Option.none [])

-- fn zero params, with return type
macro_rules
  | `(rust_item| $vis:rust_vis* fn $name:ident () -> $ret:rust_ty $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let retExpr  ← `(term| $(⟨ret⟩))
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr FnModifiers.none
        (Ident.mk $(Lean.quote nameIdent)) Option.none [] (Option.some $retExpr) Option.none
        (Option.some $bodyExpr) Option.none [])

-- async fn zero params, no return type
macro_rules
  | `(rust_item| $vis:rust_vis* async fn $name:ident () $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr
        (FnModifiers.mods (Option.some GenBlockKind.async_) Bool.false Bool.false Bool.false Option.none)
        (Ident.mk $(Lean.quote nameIdent))
        Option.none [] Option.none Option.none
        (Option.some $bodyExpr) Option.none [])

-- async fn zero params, with return type
macro_rules
  | `(rust_item| $vis:rust_vis* async fn $name:ident () -> $ret:rust_ty $body:rust_block) => do
    let visExpr ← if vis.isEmpty then `(term| Option.none) else `(term| Option.some Visibility.pub)
    let nameIdent := name.getId.toString
    let retExpr ← `(term| $(⟨ret⟩))
    let bodyExpr ← `(term| $(⟨body⟩))
    `(term| Item.fn_ [] $visExpr
        (FnModifiers.mods (Option.some GenBlockKind.async_) Bool.false Bool.false Bool.false Option.none)
        (Ident.mk $(Lean.quote nameIdent))
        Option.none [] (Option.some $retExpr) Option.none
        (Option.some $bodyExpr) Option.none [])
