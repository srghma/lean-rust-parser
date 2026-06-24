module

import Aesop

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
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

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
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

instance : ToString Ident := ⟨(·.name)⟩

/-- A lifetime `'a`. -/
structure Lifetime where
  name : String   -- without the leading `'`
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

def Lifetime.toString (l : Lifetime) : String := "'" ++ l.name

/-- A label `'outer`. -/
structure Label where
  name : String
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

def Label.toString (l : Label) : String := "'" ++ l.name

/-- Fragment specifiers inside macro_rules patterns. -/
inductive FragmentSpecifier
  | block | expr | expr2021 | ident | item | lifetime | literal
  | meta_ | pat | patParam | path | stmt | tt | ty | vis
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

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
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

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
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

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
inductive UnaryOp | neg | deref | not deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

def UnaryOp.toString : UnaryOp → String
  | .neg => "-" | .deref => "*" | .not => "!"

/-- Range operators. -/
inductive RangeOp | exclusive | inclusive | dotDotDot deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

def RangeOp.toString : RangeOp → String
  | .exclusive => ".." | .inclusive => "..=" | .dotDotDot => "..."

/-- How a closure captures its environment (rustc `CaptureBy`). -/
inductive CaptureBy
  | value   -- `move`
  | ref_    -- default (by reference)
  | use_    -- `use` (precise capturing, nightly)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- The kind of generator block (rustc `GenBlockKind`). -/
inductive GenBlockKind
  | async_    -- `async { ... }`
  | gen       -- `gen { ... }` (nightly)
  | asyncGen  -- `async gen { ... }` (nightly)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- Whether a `match` is prefix or postfix (nightly postfix-match). -/
inductive MatchKind | prefix | postfix deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- Whether a `yield` is prefix or postfix. -/
inductive YieldKind | prefix | postfix deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- Whether a `for` loop is plain or `for await`. -/
inductive ForLoopKind | for_ | forAwait deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- Unsafe binder cast direction. -/
inductive UnsafeBinderCastKind | wrap | unwrap deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- How a macro invocation statement is terminated. -/
inductive MacStmtStyle
  | semicolon  -- `mac!(...);`
  | braces     -- `mac! { ... }` (no semicolon needed)
  | noBraces   -- `mac!(...)` used as expression statement
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- TraitBound modifier (e.g. `?Sized`). -/
inductive TraitBoundModifier | none | maybe | maybeConst deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord


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
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

-- 1. Standalone types extracted from the mutual block
-- These do not depend on the core cycle (Expr/Ty/Stmt/Item).


/-- Function modifier flags (safety, constness, asyncness, extern ABI). -/
inductive FnModifiers
  | mods (coroutine : Option GenBlockKind)
         (isConst : Bool)
         (isUnsafe : Bool)
         (isDefault : Bool)
         (extABI : Option (Option String))  -- None = no extern; some none = bare extern; some (some "C") = extern "C"
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

@[reducible] def FnModifiers.none : FnModifiers :=
  .mods Option.none false false false Option.none

/-- Token tree (opaque, stored as raw string per delimiter kind). -/
inductive TokenTree
  | parens   (content : String)
  | brackets (content : String)
  | braces   (content : String)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- A macro_rules rule: `pattern => body`. -/
inductive MacroRule
  | mk (pattern : TokenTree) (body : TokenTree)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord

/-- Use tree (import path). -/
inductive UseTree
  | path  (seg : Ident) (child : UseTree)
  | name  (id : Ident)
  | alias (id : Ident) (alias : Ident)
  | glob
  | list  (trees : List UseTree)
  | self_
  deriving Repr, Inhabited, Ord --, DecidableEq, ReflBEq, LawfulBEq

private noncomputable def UseTree.decEq (x y : UseTree) : Decidable (x = y) := by
  cases x <;> cases y
  all_goals expose_names;
  · exact Classical.propDecidable (path seg child = path seg_1 child_1)
  · exact Classical.propDecidable (path seg child = name id)
  · exact Classical.propDecidable (path seg child = UseTree.alias id alias)
  · exact Classical.propDecidable (path seg child = glob)
  · exact Classical.propDecidable (path seg child = list trees)
  · exact Classical.propDecidable (path seg child = self_)
  · exact Classical.propDecidable (name id = path seg child)
  · exact Classical.propDecidable (name id = name id_1)
  · exact Classical.propDecidable (name id = UseTree.alias id_1 alias)
  · exact Classical.propDecidable (name id = glob)
  · exact Classical.propDecidable (name id = list trees)
  · exact Classical.propDecidable (name id = self_)
  · exact Classical.propDecidable (UseTree.alias id alias = path seg child)
  · exact Classical.propDecidable (UseTree.alias id alias = name id_1)
  · exact Classical.propDecidable (UseTree.alias id alias = UseTree.alias id_1 alias_1)
  · exact Classical.propDecidable (UseTree.alias id alias = glob)
  · exact Classical.propDecidable (UseTree.alias id alias = list trees)
  · exact Classical.propDecidable (UseTree.alias id alias = self_)
  · exact Classical.propDecidable (glob = path seg child)
  · exact Classical.propDecidable (glob = name id)
  · exact Classical.propDecidable (glob = UseTree.alias id alias)
  · simp_all only
    exact instDecidableTrue
  · exact Classical.propDecidable (glob = list trees)
  · exact Classical.propDecidable (glob = self_)
  · exact Classical.propDecidable (list trees = path seg child)
  · exact Classical.propDecidable (list trees = name id)
  · exact Classical.propDecidable (list trees = UseTree.alias id alias)
  · exact Classical.propDecidable (list trees = glob)
  · exact Classical.propDecidable (list trees = list trees_1)
  · exact Classical.propDecidable (list trees = self_)
  · exact Classical.propDecidable (self_ = path seg child)
  · exact Classical.propDecidable (self_ = name id)
  · exact Classical.propDecidable (self_ = UseTree.alias id alias)
  · exact Classical.propDecidable (self_ = glob)
  · exact Classical.propDecidable (self_ = list trees)
  · simp_all only
    exact instDecidableTrue
end

noncomputable instance : DecidableEq UseTree := UseTree.decEq

mutual
  def UseTree.beq : UseTree → UseTree → Bool
    | path seg1 child1, path seg2 child2 => seg1 == seg2 && beq child1 child2
    | name id1, name id2 => id1 == id2
    | alias id1 al1, alias id2 al2 => id1 == id2 && al1 == al2
    | glob, glob => true
    | list trees1, list trees2 => list_beq trees1 trees2
    | self_, self_ => true
    | _, _ => false

  def UseTree.list_beq : List UseTree → List UseTree → Bool
    | [], [] => true
    | t1 :: ts1, t2 :: ts2 => beq t1 t2 && list_beq ts1 ts2
    | _, _ => false
end

instance : BEq UseTree where
  beq := UseTree.beq

theorem UseTree.list_beq_eq (xs ys : List UseTree) : UseTree.list_beq xs ys = (xs == ys) := by
  induction xs generalizing ys with
  | nil =>
    cases ys <;> rfl
  | cons x xs ih =>
    cases ys with
    | nil => rfl
    | cons y ys =>
      dsimp [BEq.beq, UseTree.beq, UseTree.list_beq]
      rw [ih]
      rfl

mutual
  theorem UseTree.beq_self (x : UseTree) : (x == x) = true := by
    cases x with
    | path seg child =>
      change (seg == seg && child == child) = true
      simp [beq_self child]
    | name id =>
      change (id == id) = true
      simp
    | alias id al =>
      change (id == id && al == al) = true
      simp
    | glob =>
      rfl
    | list trees =>
      change (list_beq trees trees) = true
      rw [list_beq_eq]
      exact list_beq_self trees
    | self_ =>
      rfl

  theorem UseTree.list_beq_self (xs : List UseTree) : (xs == xs) = true := by
    cases xs with
    | nil => rfl
    | cons y ys =>
      change (y == y && ys == ys) = true
      rw [beq_self y, list_beq_self ys]
      rfl
end

mutual
  theorem UseTree.eq_of_beq_internal (x y : UseTree) (h : UseTree.beq x y = true) : x = y := by
    cases x <;> cases y
    all_goals (try (dsimp [beq] at h; contradiction))
    · -- path / path
      dsimp [beq] at h
      simp at h
      have ⟨h1, h2⟩ := h
      rw [h1, eq_of_beq_internal _ _ h2]
    · -- name / name
      dsimp [beq] at h
      simp at h
      rw [h]
    · -- alias / alias
      dsimp [beq] at h
      simp at h
      have ⟨h1, h2⟩ := h
      rw [h1, h2]
    · -- glob / glob
      rfl
    · -- list / list
      dsimp [beq] at h
      rw [list_eq_of_beq_internal _ _ h]
    · -- self / self
      rfl

  theorem UseTree.list_eq_of_beq_internal (xs ys : List UseTree) (h : UseTree.list_beq xs ys = true) : xs = ys := by
    cases xs <;> cases ys
    all_goals (try (dsimp [list_beq] at h; contradiction))
    · rfl
    · -- cons / cons
      dsimp [list_beq] at h
      simp at h
      have ⟨h1, h2⟩ := h
      rw [eq_of_beq_internal _ _ h1, list_eq_of_beq_internal _ _ h2]
end

instance : LawfulBEq UseTree where
  eq_of_beq := by
    intro x y h
    change UseTree.beq x y = true at h
    exact UseTree.eq_of_beq_internal x y h
  rfl := by
    intro x
    exact UseTree.beq_self x

instance : ReflBEq UseTree where
  rfl := by intro x; exact UseTree.beq_self x
