module

@[expose] public section

-- A complete Lean 4 AST for Rust, derived from rustc_ast and the syn crate,
-- covering all stable and nightly constructs.
-- This file contains only data type definitions (no pretty-printing, no elaboration).

/-! ──────────────────────────────────────────────────────────────
    § 1  Primitive leaf types
──────────────────────────────────────────────────────────────── -/

/-- Rust primitive scalar types (including f16/f128 nightly types). -/
inductive PrimitiveType
  | u8 | i8 | u16 | i16 | u32 | i32 | u64 | i64
  | u128 | i128 | isize | usize | f16 | f32 | f64 | f128
  | bool_ | str_ | char_
  deriving Repr, DecidableEq

def PrimitiveType.toString : PrimitiveType → String
  | .u8    => "u8"    | .i8    => "i8"
  | .u16   => "u16"   | .i16   => "i16"
  | .u32   => "u32"   | .i32   => "i32"
  | .u64   => "u64"   | .i64   => "i64"
  | .u128  => "u128"  | .i128  => "i128"
  | .isize => "isize" | .usize => "usize"
  | .f16   => "f16"   | .f32   => "f32"
  | .f64   => "f64"   | .f128  => "f128"
  | .bool_ => "bool"  | .str_  => "str"  | .char_ => "char"

/-- An identifier (possibly raw `r#foo`). -/
structure Ident where
  name : String
  deriving Repr, DecidableEq, Inhabited

instance : ToString Ident := ⟨(·.name)⟩

/-- A lifetime `'a`. -/
structure Lifetime where
  name : String   -- without the leading `'`
  deriving Repr, DecidableEq

def Lifetime.toString (l : Lifetime) : String := "'" ++ l.name

/-- A label `'outer`. -/
structure Label where
  name : String
  deriving Repr, DecidableEq

def Label.toString (l : Label) : String := "'" ++ l.name

/-- Fragment specifiers inside macro_rules patterns. -/
inductive FragmentSpecifier
  | block | expr | expr2021 | ident | item | lifetime | literal
  | meta_ | pat | patParam | path | stmt | tt | ty | vis
  deriving Repr, DecidableEq

def FragmentSpecifier.toString : FragmentSpecifier → String
  | .block    => "block"    | .expr     => "expr"
  | .expr2021 => "expr_2021"| .ident    => "ident"
  | .item     => "item"     | .lifetime => "lifetime"
  | .literal  => "literal"  | .meta_    => "meta"
  | .pat      => "pat"      | .patParam => "pat_param"
  | .path     => "path"     | .stmt     => "stmt"
  | .tt       => "tt"       | .ty       => "ty"
  | .vis      => "vis"

/-- Visibility modifier (matches rustc's `VisibilityKind`). -/
inductive Visibility
  | inherited            -- default (no modifier)
  | pub                  -- `pub`
  | pubCrate             -- `pub(crate)`
  | pubSelf              -- `pub(self)`
  | pubSuper             -- `pub(super)`
  | pubIn (path : String) -- `pub(in path)`
  | crateKw              -- bare `crate` (old-style)
  deriving Repr, DecidableEq

def Visibility.toString : Visibility → String
  | .inherited  => ""
  | .pub        => "pub"
  | .pubCrate   => "pub(crate)"
  | .pubSelf    => "pub(self)"
  | .pubSuper   => "pub(super)"
  | .pubIn p    => s!"pub(in {p})"
  | .crateKw    => "crate"

/-- Binary operators (arithmetic, logical, bitwise, comparison). -/
inductive BinOp
  | and | or | bitAnd | bitOr | bitXor
  | eq | ne | lt | le | gt | ge
  | shl | shr | add | sub | mul | div | rem
  deriving Repr, DecidableEq

def BinOp.toString : BinOp → String
  | .and    => "&&" | .or     => "||"
  | .bitAnd => "&"  | .bitOr  => "|"  | .bitXor => "^"
  | .eq     => "==" | .ne     => "!=" | .lt     => "<"  | .le => "<="
  | .gt     => ">"  | .ge     => ">="
  | .shl    => "<<" | .shr    => ">>"
  | .add    => "+"  | .sub    => "-"  | .mul    => "*"
  | .div    => "/"  | .rem    => "%"

/-- Compound-assignment operators. -/
inductive CompoundOp
  | addEq | subEq | mulEq | divEq | remEq
  | andEq | orEq  | xorEq | shlEq | shrEq
  deriving Repr, DecidableEq

def CompoundOp.toString : CompoundOp → String
  | .addEq => "+=" | .subEq => "-=" | .mulEq => "*="
  | .divEq => "/=" | .remEq => "%=" | .andEq => "&="
  | .orEq  => "|=" | .xorEq => "^=" | .shlEq => "<<=" | .shrEq => ">>="

/-- Unary operators. -/
inductive UnaryOp | neg | deref | not deriving Repr, DecidableEq

def UnaryOp.toString : UnaryOp → String
  | .neg => "-" | .deref => "*" | .not => "!"

/-- Range operators. -/
inductive RangeOp | exclusive | inclusive | dotDotDot deriving Repr, DecidableEq

def RangeOp.toString : RangeOp → String
  | .exclusive => ".." | .inclusive => "..=" | .dotDotDot => "..."

/-- How a closure captures its environment (rustc `CaptureBy`). -/
inductive CaptureBy
  | value   -- `move`
  | ref_    -- default (by reference)
  | use_    -- `use` (precise capturing, nightly)
  deriving Repr, DecidableEq

/-- The kind of generator block (rustc `GenBlockKind`). -/
inductive GenBlockKind
  | async_    -- `async { ... }`
  | gen       -- `gen { ... }` (nightly)
  | asyncGen  -- `async gen { ... }` (nightly)
  deriving Repr, DecidableEq

/-- Whether a `match` is prefix or postfix (nightly postfix-match). -/
inductive MatchKind | prefix | postfix deriving Repr, DecidableEq

/-- Whether a `yield` is prefix or postfix. -/
inductive YieldKind | prefix | postfix deriving Repr, DecidableEq

/-- Whether a `for` loop is plain or `for await`. -/
inductive ForLoopKind | for_ | forAwait deriving Repr, DecidableEq

/-- Unsafe binder cast direction. -/
inductive UnsafeBinderCastKind | wrap | unwrap deriving Repr, DecidableEq

/-- How a macro invocation statement is terminated. -/
inductive MacStmtStyle
  | semicolon  -- `mac!(...);`
  | braces     -- `mac! { ... }` (no semicolon needed)
  | noBraces   -- `mac!(...)` used as expression statement
  deriving Repr, DecidableEq

/-- TraitBound modifier (e.g. `?Sized`). -/
inductive TraitBoundModifier | none | maybe | maybeConst deriving Repr, DecidableEq


/-- Literal values. -/
inductive Literal
  | int_    (raw : String)
  | float_  (raw : String)
  | str_    (raw : String)       -- `"hello"`
  | byteStr (raw : String)       -- `b"hello"`
  | cStr    (raw : String)       -- `c"hello"` (C-string literal)
  | rawStr  (raw : String)       -- `r#"..."#`
  | char_   (raw : String)       -- `'a'`
  | byte_   (raw : String)       -- `b'x'`
  | bool_   (b : Bool)
  deriving Repr

-- 1. Standalone types extracted from the mutual block
-- These do not depend on the core cycle (Expr/Ty/Stmt/Item).


/-- Function modifier flags (safety, constness, asyncness, extern ABI). -/
inductive FnModifiers
  | mods (coroutine : Option GenBlockKind)
         (isConst : Bool)
         (isUnsafe : Bool)
         (isDefault : Bool)
         (extABI : Option (Option String))  -- None = no extern; some none = bare extern; some (some "C") = extern "C"
  deriving Repr

@[reducible] def FnModifiers.none : FnModifiers :=
  .mods Option.none false false false Option.none

/-- Token tree (opaque, stored as raw string per delimiter kind). -/
inductive TokenTree
  | parens   (content : String)
  | brackets (content : String)
  | braces   (content : String)
  deriving Repr
/-- A macro_rules rule: `pattern => body`. -/
inductive MacroRule
  | mk (pattern : TokenTree) (body : TokenTree)
  deriving Repr
/-- Use tree (import path). -/
inductive UseTree
  | path  (seg : Ident) (child : UseTree)
  | name  (id : Ident)
  | alias (id : Ident) (alias : Ident)
  | glob
  | list  (trees : List UseTree)
  | self_
  deriving Repr
