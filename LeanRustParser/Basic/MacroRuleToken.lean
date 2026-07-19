module

/-! Rust concrete-token and token-stream data, structurally aligned with
`rustc_ast::token` and `rustc_ast::tokenstream`.

Non-doc comments are intentionally absent: the source lexer reduces them to
spacing.  Rust keeps doc comments as `TokenKind::DocComment`, represented
below by `MacroRuleToken.docComment`.
-/

@[expose] public section

-- 1. The string is nonempty.
-- 2. Its first Unicode scalar is either:
--     - _, or
--     - Unicode XID_Start.
--
-- 3. Every remaining scalar is either:
--     - Unicode XID_Continue, or
--     - _ (already included by XID_Continue in practice).
--
-- 4. It contains no invalid UTF-8 — Lean String already guarantees this.
-- 5. The r# raw-identifier prefix is not part of name; it belongs in token metadata.
--
-- Examples:
--
-- x          valid
-- _          valid
-- café       valid
-- 变量       valid
-- foo2       valid
-- 2foo       invalid
-- foo-bar    invalid
-- ""         invalid
--
-- Keyword status is not part of IsRustIdentifier:
--
-- fn         lexically identifier-shaped
-- self       lexically identifier-shaped
-- r#fn       raw identifier token
--
-- Whether fn is accepted as a name depends on parser position and edition, not on the basic character-validity proof.

/-- Lean's stand-in for rustc's interned `rustc_span::Symbol`. -/
-- abbrev Symbol := String

structure Ident where
  name : String
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::token::NtPatKind`. -/
inductive NtPatKind where
  | patWithOr
  | patParam (inferred : Bool)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::token::NtExprKind`. -/
inductive NtExprKind where
  | expr
  | expr2021 (inferred : Bool)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_errors::ErrorGuaranteed` without its diagnostic-context lifetime. -/
-- structure ErrorGuaranteed where
--   id : Nat
--   deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive MetaVarKind where
  | item | block | stmt
  | pat (kind : NtPatKind)
  | expr (kind : NtExprKind) (canBeginLiteralMaybeMinus : Bool) (canBeginStringLiteral : Bool)
  | ty (isPath : Bool)
  | ident | lifetime | literal
  | meta_ (hasMetaForm : Bool)
  | path | vis | guard | tt
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive InvisibleOrigin where
  | metaVar (kind : MetaVarKind)
  | procMacro
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive Delimiter where
  | parenthesis | brace | bracket
  | invisible (origin : InvisibleOrigin)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive IdentIsRaw where
  | no | yes
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive LitKind where
  | bool | byte | char | integer | float | str
  | strRaw (hashes : Nat)
  | byteStr | byteStrRaw (hashes : Nat)
  | cStr | cStrRaw (hashes : Nat)
  | err -- (error : ErrorGuaranteed)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

structure Lit where
  kind : LitKind
  symbol : String
  suffix : Option String
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::token::CommentKind`. -/
inductive CommentKind where
  | line | block
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- `rustc_ast::ast::AttrStyle`, used by doc-comment tokens. -/
inductive AttrStyle where
  | outer | inner
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- Complete `rustc_ast::token::TokenKind` surface. -/
inductive MacroRuleToken where
  | eq | lt | le | eqEq | ne | ge | gt | andAnd | orOr | bang | tilde
  | plus | minus | star | slash | percent | caret | and | or | shl | shr
  | plusEq | minusEq | starEq | slashEq | percentEq | caretEq | andEq | orEq | shlEq | shrEq

  | at | dot | dotDot | dotDotDot | dotDotEq | comma | semi | colon | pathSep
  | rArrow | lArrow | fatArrow | pound | dollar | question | singleQuote
  | openParen | closeParen | openBrace | closeBrace | openBracket | closeBracket
  | openInvisible (origin : InvisibleOrigin) | closeInvisible (origin : InvisibleOrigin)

  | literal (lit : Lit)
  | ident (symbol : String) (raw : IdentIsRaw)
  | ntIdent (ident : Ident) (raw : IdentIsRaw)
  | lifetime (symbol : String) (raw : IdentIsRaw)
  | ntLifetime (ident : Ident) (raw : IdentIsRaw)
  | docComment (kind : CommentKind) (style : AttrStyle) (symbol : String)
  | eof
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive Spacing where
  | alone | joint | jointHidden
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

structure DelimSpacing where
  open_ : Spacing
  close : Spacing
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive MacroRuleTokenTree where
  | token (token : MacroRuleToken) (spacing : Spacing)
  | delimited (spacing : DelimSpacing) (delimiter : Delimiter) (tokens : List MacroRuleTokenTree)
  deriving Repr, BEq, Inhabited

abbrev MacroRuleTokenStream := List MacroRuleTokenTree
