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

-- Omitted: `rustc_errors::ErrorGuaranteed` is diagnostic-context state and
-- this source token tree deliberately contains no diagnostics.
-- /-- `rustc_errors::ErrorGuaranteed` without its diagnostic-context lifetime. -/
-- structure ErrorGuaranteed where
--   id : Nat
--   deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

-- Omitted: `MetaVarKind` stores declarative-macro matcher and reparsing
-- metadata (including inferred-edition flags). It is not source syntax.
-- inductive MetaVarKind where
--  | item | block | stmt
--  | pat (kind : NtPatKind)
--  | expr (kind : NtExprKind) (canBeginLiteralMaybeMinus : Bool) (canBeginStringLiteral : Bool)
--  | ty (isPath : Bool)
--  | ident | lifetime | literal
--  | meta_ (hasMetaForm : Bool)
--  | path | vis | guard | tt
--  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

--
-- Omitted: `InvisibleOrigin` records macro-expansion provenance. Invisible
-- delimiters do not occur in a source token tree.
-- inductive InvisibleOrigin where
--  | metaVar (kind : MetaVarKind)
--  | procMacro


inductive Delimiter where
  | parenthesis | brace | bracket
  -- Omitted: invisible delimiters are inserted by macro expansion, not source.
  -- | invisible (origin : InvisibleOrigin)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive IdentIsRaw where
  | no | yes
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive LitKind where
  | bool | byte | char | integer | float | str
  | strRaw (hashes : Nat)
  | byteStr | byteStrRaw (hashes : Nat)
  | cStr | cStrRaw (hashes : Nat)
  -- Omitted: rustc's `Err(ErrorGuaranteed)` is a recovery token tied to its
  -- diagnostic context; this source token tree contains no diagnostics.
  -- | err -- (error : ErrorGuaranteed)
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
  -- Omitted: invisible delimiters are macro-expansion provenance, not source.
  -- | openInvisible (origin : InvisibleOrigin) | closeInvisible (origin : InvisibleOrigin)

  | literal (lit : Lit)
  | ident (symbol : String) (raw : IdentIsRaw)
  -- Omitted: interpolated nonterminal identifiers are expansion output.
  -- | ntIdent (ident : Ident) (raw : IdentIsRaw)
  | lifetime (symbol : String) (raw : IdentIsRaw)
  -- Omitted: interpolated nonterminal lifetimes are expansion output.
  -- | ntLifetime (ident : Ident) (raw : IdentIsRaw)
  | docComment (kind : CommentKind) (style : AttrStyle) (symbol : String)
  | eof
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive Spacing where
  | alone | joint
  -- Omitted: `jointHidden` is macro-expansion token-stream metadata. `alone`
  -- and `joint` remain because source punctuation needs them for tokenization.
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

structure DelimSpacing where
  open_ : Spacing
  close : Spacing
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

inductive MacroRuleTokenTree where
  | token (token : MacroRuleToken) (spacing : Spacing)
  | delimited (spacing : DelimSpacing) (delimiter : Delimiter) (tokens : List MacroRuleTokenTree)
  deriving Repr, Inhabited, Ord, Hashable

mutual
  /-- Structural equality for one token tree.  This is explicit because the
  tree recurs through `List MacroRuleTokenTree`. -/
  def macroRuleTokenTreeDecEq :
      (a b : MacroRuleTokenTree) → Decidable (a = b)
    | .token tok spacing, .token tok' spacing' =>
        match (inferInstance : Decidable (tok = tok')),
          (inferInstance : Decidable (spacing = spacing')) with
        | .isTrue hToken, .isTrue hSpacing =>
            .isTrue (by subst tok'; subst spacing'; rfl)
        | .isFalse hToken, _ =>
            .isFalse (by intro h; cases h; exact hToken rfl)
        | _, .isFalse hSpacing =>
            .isFalse (by intro h; cases h; exact hSpacing rfl)
    | .token _ _, .delimited _ _ _ => .isFalse (by intro h; cases h)
    | .delimited _ _ _, .token _ _ => .isFalse (by intro h; cases h)
    | .delimited spacing delimiter tokens, .delimited spacing' delimiter' tokens' =>
        match (inferInstance : Decidable (spacing = spacing')),
          (inferInstance : Decidable (delimiter = delimiter')),
          macroRuleTokenTreeListDecEq tokens tokens' with
        | .isTrue hSpacing, .isTrue hDelimiter, .isTrue hTokens =>
            .isTrue (by subst spacing'; subst delimiter'; subst tokens'; rfl)
        | .isFalse hSpacing, _, _ =>
            .isFalse (by intro h; cases h; exact hSpacing rfl)
        | _, .isFalse hDelimiter, _ =>
            .isFalse (by intro h; cases h; exact hDelimiter rfl)
        | _, _, .isFalse hTokens =>
            .isFalse (by intro h; cases h; exact hTokens rfl)

  /-- Structural equality for the recursive child list. -/
  def macroRuleTokenTreeListDecEq :
      (xs ys : List MacroRuleTokenTree) → Decidable (xs = ys)
    | [], [] => .isTrue rfl
    | [], _ :: _ => .isFalse (by intro h; cases h)
    | _ :: _, [] => .isFalse (by intro h; cases h)
    | x :: xs, y :: ys =>
        match macroRuleTokenTreeDecEq x y, macroRuleTokenTreeListDecEq xs ys with
        | .isTrue hHead, .isTrue hTail =>
            .isTrue (by cases hHead; cases hTail; rfl)
        | .isFalse hHead, _ =>
            .isFalse (by intro h; cases h; exact hHead rfl)
        | _, .isFalse hTail =>
            .isFalse (by intro h; cases h; exact hTail rfl)
end

/-- Explicit structural equality for macro token trees. -/
instance : DecidableEq MacroRuleTokenTree := macroRuleTokenTreeDecEq

/-- `BEq` is deliberately defined from the explicit `DecidableEq` above. -/
instance : BEq MacroRuleTokenTree where
  beq a b := decide (a = b)

/-- The chosen boolean equality is reflexive. -/
instance : ReflBEq MacroRuleTokenTree where
  rfl := by simp

/-- The chosen boolean equality is exactly structural equality. -/
instance : LawfulBEq MacroRuleTokenTree where
  eq_of_beq := of_decide_eq_true
  rfl := of_decide_eq_self_eq_true _

abbrev MacroRuleTokenStream := List MacroRuleTokenTree
