module

public import LeanRustParser.Basic.MacroRuleToken

@[expose] public section

/-- `rustc_ast::RangeLimits`. -/
inductive RangeLimits where
  | halfOpen | closed
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::BorrowKind`, reduced to source-level reference forms. -/
inductive BorrowKind where
  | ref_ | raw | pin
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::Mutability`. -/
inductive Mutability where
  | not | mut
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::Safety`, without the keyword span. -/
inductive Safety where
  | safe | unsafe_ | default_
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::TraitObjectSyntax`. -/
inductive TraitObjectSyntax where
  | dyn_ | none
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::BlockCheckMode` for source-written blocks.
`UnsafeSource::CompilerGenerated` is omitted because it is introduced by
rustc after parsing and is not source syntax. -/
inductive BlockCheckMode where
  | default_ | unsafe_
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::BindingMode`. -/
structure BindingMode where
  byRef : Bool
  mutbl : Mutability
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::PatFieldsRest`, omitting diagnostic recovery state. -/
inductive PatFieldsRest where
  | rest | none
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::DelegationSuffixes`, without the glob span. -/
inductive DelegationSuffixes
  | list (items : List (Ident × Option Ident))
  | glob
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Hashable

/-- `rustc_ast::RangeSyntax`.  It distinguishes legacy `...` from `..=`;
both are semantically inclusive but remain distinct source spellings. -/
inductive RangeSyntax where
  | dotDotDot | dotDotEq
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::RangeEnd`, without its enclosing span. -/
inductive RangeEnd where
  | excluded | included (spelling : RangeSyntax)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::Pinnedness`, without the `pin` keyword span. -/
inductive Pinnedness where
  | notPinned | pinned
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::InlineAsmRegOrRegClass`. -/
inductive InlineAsmRegOrRegClass where
  | reg (name : String)
  | regClass (name : String)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::InlineAsmTemplatePiece`, without placeholder spans. -/
inductive InlineAsmTemplatePiece where
  | string (text : String)
  | placeholder (operandIdx : Nat) (modifier : Option Char)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::AsmMacro`. -/
inductive AsmMacro where
  | asm | globalAsm | nakedAsm
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- Source-level equivalent of rustc's `InlineAsmOptions` bitflags. -/
structure InlineAsmOptions where
  pure : Bool
  nomem : Bool
  readonly : Bool
  preservesFlags : Bool
  noreturn : Bool
  nostack : Bool
  attSyntax : Bool
  raw : Bool
  mayUnwind : Bool
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::DelimArgs`, without delimiter spans.  This is independent of
the recursive source AST: its payload is a macro token stream. -/
structure DelimArgs where
  delimiter : Delimiter
  tokens : MacroRuleTokenStream
  deriving Repr, BEq, Inhabited, DecidableEq, ReflBEq, LawfulBEq, Ord, Hashable

/-- The source spelling of a format-string argument position.  rustc also
stores `index : Result<usize, usize>` after resolving this spelling into its
`FormatArgs.arguments` list.  That field is intentionally omitted: it is
derived resolution/diagnostic metadata, and `Err(n)` only remembers an
out-of-range index for error reporting. -/
inductive FormatArgPosition
  | implicit
  | number (value : Nat)
  | named (name : Ident)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive FormatTrait | display | debug | lowerExp | upperExp | octal | pointer | binary | lowerHex | upperHex
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive FormatAlignment | left | right | center
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive FormatSign | plus | minus
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive FormatDebugHex | lower | upper
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive FormatCount | literal (value : Nat) | argument (position : FormatArgPosition)
  deriving Repr, Inhabited, BEq, DecidableEq, ReflBEq, LawfulBEq, Ord, Hashable

structure FormatOptions where
  width : Option FormatCount
  precision : Option FormatCount
  alignment : Option FormatAlignment
  fill : Option Char
  sign : Option FormatSign
  alternate : Bool
  zeroPad : Bool
  debugHex : Option FormatDebugHex
  deriving Repr, Inhabited, BEq, DecidableEq, ReflBEq, LawfulBEq, Ord, Hashable

structure FormatPlaceholder where
  argument : FormatArgPosition
  formatTrait : FormatTrait
  formatOptions : FormatOptions
  deriving Repr, Inhabited, BEq, DecidableEq, ReflBEq, LawfulBEq, Ord, Hashable

inductive FormatArgsPiece
  | literal (text : String)
  | placeholder (placeholder : FormatPlaceholder)
  deriving Repr, Inhabited, BEq, DecidableEq, ReflBEq, LawfulBEq, Ord, Hashable

inductive FormatArgumentKind
  | normal
  | named (ident : Ident)
  | captured (ident : Ident)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- A source-tree stand-in for rustc's interned `ByteSymbol`. -/
structure ByteSymbol where
  bytes : List UInt8
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

-- Omitted: `rustc_errors::ErrorGuaranteed` proves that rustc emitted a
-- diagnostic. Diagnostics are deliberately outside this source AST.
-- /-- `rustc_errors::ErrorGuaranteed`, represented by the emitted diagnostic.
-- The diagnostic store can replace this string with an opaque ID later. -/
-- structure ErrorGuaranteed where
--   diagnostic : String
--   deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

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
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

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

/-- `rustc_ast::Lifetime`, without its ID and span. -/
structure Lifetime where
  ident : Ident
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

def Lifetime.toString (l : Lifetime) : String := "'" ++ l.ident.name

/-- `rustc_ast::Label`, without its ID and span. -/
structure Label where
  ident : Ident
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

def Label.toString (l : Label) : String := "'" ++ l.ident.name

/-- Fragment specifiers inside macro_rules patterns. -/
inductive FragmentSpecifier
  | block | expr | expr2021 | ident | item | lifetime | literal
  | meta_ | pat | patParam | path | stmt | tt | ty | vis
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

def FragmentSpecifier.toString : FragmentSpecifier → String
  | .block    => "block"    | .expr     => "expr"
  | .expr2021 => "expr_2021"| .ident    => "ident"
  | .item     => "item"     | .lifetime => "lifetime"
  | .literal  => "literal"  | .meta_    => "meta"
  | .pat      => "pat"      | .patParam => "pat_param"
  | .path     => "path"     | .stmt     => "stmt"
  | .tt       => "tt"       | .ty       => "ty"
  | .vis      => "vis"

/-- `rustc_ast::BinOpKind`.  The outer rustc `BinOp` only adds a span, so this
source tree stores the kind directly. -/
inductive BinOpKind
  | add | sub | mul | div | rem | and | or | bitXor | bitAnd | bitOr
  | shl | shr | eq | lt | le | ne | ge | gt
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::UnOp`. -/
inductive UnOp | deref | not | neg
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- How a closure captures its environment (`rustc_ast::CaptureBy`). -/
inductive CaptureBy
  | value | ref_ | use_
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast_ir::Movability`, without the keyword span.  `Movable` is the
ordinary source form; `Static` is retained because rustc stores it on closures
created for async/generator syntax. -/
inductive Movability
  | static_ | movable
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- The kind of generator block (`rustc_ast::GenBlockKind`). -/
inductive GenBlockKind | async_ | gen | asyncGen
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::MatchKind`. -/
inductive MatchKind | prefix | postfix
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::ForLoopKind`. -/
inductive ForLoopKind | for_ | forAwait
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::UnsafeBinderCastKind`. -/
inductive UnsafeBinderCastKind | wrap | unwrap
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::MacStmtStyle`. -/
inductive MacStmtStyle | semicolon | braces | noBraces
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::BoundPolarity`, without keyword spans. -/
inductive BoundPolarity | positive | negative | maybe
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::BoundConstness`, without keyword spans. -/
inductive BoundConstness | never | always | maybe
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::BoundAsyncness`, without the `async` span. -/
inductive BoundAsyncness | normal | async_
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::TraitBoundModifiers`, without spans. -/
structure TraitBoundModifiers where
  constness : BoundConstness
  asyncness : BoundAsyncness
  polarity : BoundPolarity
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::Parens`.  It records source parentheses around a trait bound;
unlike spans, this affects the concrete syntax and is retained. -/
inductive Parens | yes | no
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::Const`, without its keyword span. -/
inductive Const | yes | no
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::CoroutineKind`, omitting its span and generated node IDs.  The
IDs are lowering metadata; source syntax is fully represented by the variant. -/
inductive CoroutineKind | async_ | gen | asyncGen
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::StrStyle`. -/
inductive StrStyle | cooked | raw (hashes : Nat)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::StrLit`, without span. `symbolUnescaped` is intentionally
omitted because it is derived while decoding the literal rather than written
source syntax. -/
structure StrLit where
  symbol : String
  suffix : Option String
  style : StrStyle
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::Extern`, without keyword spans. -/
inductive Extern | none | implicit | explicit (abi : StrLit)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::FnHeader`, without keyword spans. -/
structure FnHeader where
  constness : Const
  coroutineKind : Option CoroutineKind
  safety : Safety
  ext : Extern
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::Defaultness`, without keyword spans. -/
inductive Defaultness | implicit | default_ | final_
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::IsAuto`. -/
inductive IsAuto | yes | no
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::Inline`, with the parse-error diagnostic deliberately omitted.
`yes` is an inline module body and `no` is a loaded outlined module. -/
inductive Inline | yes | no
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::DelegationSource`.  `List` carries a `LocalExpnId` in rustc;
that ID is expansion metadata, so this source tree retains only which written
delegation form produced the item. -/
inductive DelegationSource | single | list | glob
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::ImplPolarity`, without the `!` span. -/
inductive ImplPolarity | positive | negative
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::MacroDef`, without the lowering-only `eii_declaration` field.
That field is populated for a built-in attribute macro after name-resolution
work and is not source syntax. -/
structure MacroDef where
  body : DelimArgs
  macroRules : Bool
  deriving Repr
