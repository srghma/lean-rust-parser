module

/-! Rust source lexer.

This module deliberately does not import macro token-tree types.  It is the
source boundary: it converts a `String` into source `LexToken`s.  Macro token
trees are a later parser/AST concern and must not shape lexical output.
-/

@[expose] public section

namespace LeanRustParser

def maxErrorTokenLength : Nat := 120

/-- Source equivalent of `rustc_ast::token::IdentIsRaw`. -/
inductive LexIdentIsRaw where
  | no | yes
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- Source keywords recognized by the parser. -/
inductive LexKeyword where
  | as_ | async_ | break_ | const_ | continue_ | crate_ | default_ | dyn_ | else_
  | enum_ | extern_ | false_ | fn_ | for_ | if_ | impl_ | in_ | let_ | loop_
  | macroRules | match_ | mod_ | move_ | mut_ | pub_ | ref_ | return_ | self_
  | static_ | struct_ | super_ | trait_ | true_ | type_ | union_ | unsafe_ | use_
  | where_ | while_
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- Source punctuation categories. -/
inductive LexPunctuation where
  | eq | lt | le | eqEq | ne | ge | gt | andAnd | orOr | bang | tilde
  | plus | minus | star | slash | percent | caret | and | or | shl | shr
  | plusEq | minusEq | starEq | slashEq | percentEq | caretEq | andEq | orEq | shlEq | shrEq
  | at | dot | dotDot | dotDotDot | dotDotEq | comma | semi | colon | pathSep
  | rArrow | lArrow | fatArrow | pound | dollar | question | singleQuote
  | openParen | closeParen | openBrace | closeBrace | openBracket | closeBracket
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- Source literal kind.  The token text remains exactly as written. -/
inductive LexLitKind where
  | byte | char | integer | float | str | strRaw (hashes : Nat)
  | byteStr | byteStrRaw (hashes : Nat) | cStr | cStrRaw (hashes : Nat)
  deriving Repr, DecidableEq, BEq, Inhabited, ReflBEq, LawfulBEq, Ord, Hashable

/-- Source literal token, without spans. -/
structure LexLit where
  kind : LexLitKind
  /-- The original source spelling; retaining a slice avoids allocating one
  `String` per literal. -/
  text : String.Slice
  deriving BEq, Inhabited

/-- Complete source-lexer output.  Whitespace, newlines, and comments are
tokens so a parser can either preserve or explicitly skip trivia. -/
inductive LexToken where
  | keyword (keyword : LexKeyword)
  | punctuation (punctuation : LexPunctuation)
  | ident (text : String.Slice) (raw : LexIdentIsRaw)
  | lifetime (name : String.Slice) (raw : LexIdentIsRaw)
  | literal (literal : LexLit)
  | whitespace (text : String.Slice)
  | newline (text : String.Slice)
  | lineComment (text : String.Slice)
  | blockComment (text : String.Slice)
  deriving BEq, Inhabited

def isIdentStart (c : Char) : Bool := c.isAlpha || c.toNat >= 128 || c == '_'
def isIdentContinue (c : Char) : Bool := isIdentStart c || ('0' <= c && c <= '9')
def isDigit (c : Char) : Bool := '0' <= c && c <= '9'
def isNewline (c : Char) : Bool := c == '\n' || c == '\r'
def isRustWhitespace (c : Char) : Bool :=
  c.isWhitespace || c.toNat == 0x0C || c.toNat == 0x85 || c.toNat == 0x200E ||
    c.toNat == 0x200F || c.toNat == 0x2028 || c.toNat == 0x2029

/-- Advance a validated slice position without converting source text to a list. -/
def advanceN (source : String.Slice) (pos : source.Pos) : Nat → source.Pos
  | 0 => pos
  | n + 1 => match pos.next? with | some next => advanceN source next n | none => pos

def peekN? (source : String.Slice) (pos : source.Pos) (n : Nat) : Option Char :=
  (advanceN source pos n).get?

partial def takeWhilePos (source : String.Slice) (pos : source.Pos) (p : Char → Bool) : source.Pos :=
  match pos.get? with
  | some c => if p c then takeWhilePos source (advanceN source pos 1) p else pos
  | none => pos

partial def takeLineCommentEnd (source : String.Slice) (pos : source.Pos) : source.Pos :=
  match pos.get? with
  | some c => if isNewline c then pos else takeLineCommentEnd source (advanceN source pos 1)
  | none => pos

partial def skipBlockComment (source : String.Slice) (depth : Nat) (pos : source.Pos) : source.Pos :=
  if depth == 0 then pos else
  match pos.get?, peekN? source pos 1 with
  | some '/', some '*' => skipBlockComment source (depth + 1) (advanceN source pos 2)
  | some '*', some '/' => skipBlockComment source (depth - 1) (advanceN source pos 2)
  | some _, _ => skipBlockComment source depth (advanceN source pos 1)
  | none, _ => pos

partial def takeQuotedEnd (source : String.Slice) (quote : Char) (pos : source.Pos) : source.Pos :=
  match pos.get? with
  | some '\\' => takeQuotedEnd source quote (advanceN source pos 2)
  | some c => if c == quote then advanceN source pos 1 else takeQuotedEnd source quote (advanceN source pos 1)
  | none => pos

partial def hasHashes (source : String.Slice) (pos : source.Pos) : Nat → Bool
  | 0 => true
  | n + 1 => peekN? source pos 0 == some '#' && hasHashes source (advanceN source pos 1) n

partial def takeRawStringEnd (source : String.Slice) (hashes : Nat) (pos : source.Pos) : source.Pos :=
  match pos.get? with
  | some '"' =>
      let afterQuote := advanceN source pos 1
      if hasHashes source afterQuote hashes then advanceN source afterQuote hashes
      else takeRawStringEnd source hashes (advanceN source pos 1)
  | some _ => takeRawStringEnd source hashes (advanceN source pos 1)
  | none => pos

partial def takeHashes (source : String.Slice) (pos : source.Pos) (count : Nat := 0) : Nat × source.Pos :=
  if pos.get? == some '#' then takeHashes source (advanceN source pos 1) (count + 1) else (count, pos)

def rawStringStart? (source : String.Slice) (pos : source.Pos) : Option (Nat × source.Pos) :=
  let afterR := advanceN source pos 1
  let (hashes, afterHashes) := takeHashes source afterR
  if afterHashes.get? == some '"' then some (hashes, advanceN source afterHashes 1) else none

def singlePunctuation? : Char → Option LexPunctuation
  | '=' => some .eq | '<' => some .lt | '>' => some .gt | '!' => some .bang
  | '~' => some .tilde | '+' => some .plus | '-' => some .minus | '*' => some .star
  | '/' => some .slash | '%' => some .percent | '^' => some .caret | '&' => some .and
  | '|' => some .or | '@' => some .at | '.' => some .dot | ',' => some .comma
  | ';' => some .semi | ':' => some .colon | '#' => some .pound | '$' => some .dollar
  | '?' => some .question | '\'' => some .singleQuote | '(' => some .openParen
  | ')' => some .closeParen | '{' => some .openBrace | '}' => some .closeBrace
  | '[' => some .openBracket | ']' => some .closeBracket | _ => none

/-- Maximal-munch punctuation directly into source punctuation enums. -/
def lexPunctuation (source : String.Slice) (pos : source.Pos) : Option (LexPunctuation × source.Pos) :=
  let c := peekN? source pos 0
  let c₁ := peekN? source pos 1
  let c₂ := peekN? source pos 2
  match c, c₁, c₂ with
  | some '.', some '.', some '.' => some (.dotDotDot, advanceN source pos 3)
  | some '.', some '.', some '=' => some (.dotDotEq, advanceN source pos 3)
  | some '<', some '<', some '=' => some (.shlEq, advanceN source pos 3)
  | some '>', some '>', some '=' => some (.shrEq, advanceN source pos 3)
  | some '.', some '.', _ => some (.dotDot, advanceN source pos 2)
  | some ':', some ':', _ => some (.pathSep, advanceN source pos 2)
  | some '-', some '>', _ => some (.rArrow, advanceN source pos 2)
  | some '<', some '-', _ => some (.lArrow, advanceN source pos 2)
  | some '=', some '>', _ => some (.fatArrow, advanceN source pos 2)
  | some '<', some '<', _ => some (.shl, advanceN source pos 2)
  | some '>', some '>', _ => some (.shr, advanceN source pos 2)
  | some '<', some '=', _ => some (.le, advanceN source pos 2)
  | some '>', some '=', _ => some (.ge, advanceN source pos 2)
  | some '=', some '=', _ => some (.eqEq, advanceN source pos 2)
  | some '!', some '=', _ => some (.ne, advanceN source pos 2)
  | some '&', some '&', _ => some (.andAnd, advanceN source pos 2)
  | some '|', some '|', _ => some (.orOr, advanceN source pos 2)
  | some '+', some '=', _ => some (.plusEq, advanceN source pos 2)
  | some '-', some '=', _ => some (.minusEq, advanceN source pos 2)
  | some '*', some '=', _ => some (.starEq, advanceN source pos 2)
  | some '/', some '=', _ => some (.slashEq, advanceN source pos 2)
  | some '%', some '=', _ => some (.percentEq, advanceN source pos 2)
  | some '^', some '=', _ => some (.caretEq, advanceN source pos 2)
  | some '&', some '=', _ => some (.andEq, advanceN source pos 2)
  | some '|', some '=', _ => some (.orEq, advanceN source pos 2)
  | some c, _, _ => (singlePunctuation? c).map fun punctuation => (punctuation, advanceN source pos 1)
  | none, _, _ => none

def sliceEq (left : String.Slice) (right : String) : Bool :=
  left.beq right.toSlice

def LexKeyword.ofSlice? (text : String.Slice) : Option LexKeyword :=
  if sliceEq text "as" then some .as_
  else if sliceEq text "async" then some .async_
  else if sliceEq text "break" then some .break_
  else if sliceEq text "const" then some .const_
  else if sliceEq text "continue" then some .continue_
  else if sliceEq text "crate" then some .crate_
  else if sliceEq text "default" then some .default_
  else if sliceEq text "dyn" then some .dyn_
  else if sliceEq text "else" then some .else_
  else if sliceEq text "enum" then some .enum_
  else if sliceEq text "extern" then some .extern_
  else if sliceEq text "false" then some .false_
  else if sliceEq text "fn" then some .fn_
  else if sliceEq text "for" then some .for_
  else if sliceEq text "if" then some .if_
  else if sliceEq text "impl" then some .impl_
  else if sliceEq text "in" then some .in_
  else if sliceEq text "let" then some .let_
  else if sliceEq text "loop" then some .loop_
  else if sliceEq text "macro_rules" then some .macroRules
  else if sliceEq text "match" then some .match_
  else if sliceEq text "mod" then some .mod_
  else if sliceEq text "move" then some .move_
  else if sliceEq text "mut" then some .mut_
  else if sliceEq text "pub" then some .pub_
  else if sliceEq text "ref" then some .ref_
  else if sliceEq text "return" then some .return_
  else if sliceEq text "self" then some .self_
  else if sliceEq text "static" then some .static_
  else if sliceEq text "struct" then some .struct_
  else if sliceEq text "super" then some .super_
  else if sliceEq text "trait" then some .trait_
  else if sliceEq text "true" then some .true_
  else if sliceEq text "type" then some .type_
  else if sliceEq text "union" then some .union_
  else if sliceEq text "unsafe" then some .unsafe_
  else if sliceEq text "use" then some .use_
  else if sliceEq text "where" then some .where_
  else if sliceEq text "while" then some .while_
  else none

def tokenFromIdent (text : String.Slice) (raw : LexIdentIsRaw) : LexToken :=
  if raw == .no then (LexKeyword.ofSlice? text).map LexToken.keyword |>.getD (.ident text raw)
  else .ident text raw

partial def lexFrom (source : String.Slice) (pos : source.Pos) (acc : List LexToken) :
    Except String (List LexToken) :=
  match pos.get? with
  | none => .ok acc.reverse
  | some c =>
      if isNewline c then
        let next := if c == '\r' && peekN? source pos 1 == some '\n' then advanceN source pos 2 else advanceN source pos 1
        lexFrom source next (.newline (source.slice! pos next) :: acc)
      else if isRustWhitespace c then
        let next := takeWhilePos source pos fun x => isRustWhitespace x && !isNewline x
        lexFrom source next (.whitespace (source.slice! pos next) :: acc)
      else if c == '/' && peekN? source pos 1 == some '/' then
        let next := takeLineCommentEnd source (advanceN source pos 2)
        lexFrom source next (.lineComment (source.slice! pos next) :: acc)
      else if c == '/' && peekN? source pos 1 == some '*' then
        let next := skipBlockComment source 1 (advanceN source pos 2)
        lexFrom source next (.blockComment (source.slice! pos next) :: acc)
      else if c == 'r' && peekN? source pos 1 == some '#' && (peekN? source pos 2 |>.map isIdentStart |>.getD false) then
        let begin := advanceN source pos 2
        let next := takeWhilePos source begin isIdentContinue
        lexFrom source next (tokenFromIdent (source.slice! begin next) .yes :: acc)
      else if c == 'r' then
        match rawStringStart? source pos with
        | some (hashes, content) =>
            let next := takeRawStringEnd source hashes content
            lexFrom source next (.literal ⟨.strRaw hashes, source.slice! pos next⟩ :: acc)
        | none =>
            let next := takeWhilePos source pos isIdentContinue
            lexFrom source next (tokenFromIdent (source.slice! pos next) .no :: acc)
      else if c == 'b' && peekN? source pos 1 == some '"' then
        let next := takeQuotedEnd source '"' (advanceN source pos 2)
        lexFrom source next (.literal ⟨.byteStr, source.slice! pos next⟩ :: acc)
      else if c == '"' then
        let next := takeQuotedEnd source '"' (advanceN source pos 1)
        lexFrom source next (.literal ⟨.str, source.slice! pos next⟩ :: acc)
      else if c == '\'' && (peekN? source pos 1 |>.map isIdentStart |>.getD false) then
        let begin := advanceN source pos 1
        let next := takeWhilePos source begin isIdentContinue
        lexFrom source next (.lifetime (source.slice! begin next) .no :: acc)
      else if c == '\'' then
        let next := takeQuotedEnd source '\'' (advanceN source pos 1)
        lexFrom source next (.literal ⟨.char, source.slice! pos next⟩ :: acc)
      else if isDigit c then
        let next := takeWhilePos source pos isIdentContinue
        lexFrom source next (.literal ⟨.integer, source.slice! pos next⟩ :: acc)
      else if isIdentStart c then
        let next := takeWhilePos source pos isIdentContinue
        lexFrom source next (tokenFromIdent (source.slice! pos next) .no :: acc)
      else
        match lexPunctuation source pos with
        | some (punctuation, next) => lexFrom source next (.punctuation punctuation :: acc)
        | none => .error s!"unsupported Rust character '{c}'"

/-- Return the first position after a source shebang without copying the source.
`#![...]` is an inner attribute, not a shebang. -/
def skipShebang (source : String.Slice) : source.Pos :=
  let start := source.startPos
  if peekN? source start 0 == some '#' && peekN? source start 1 == some '!' &&
      peekN? source start 2 != some '[' then
    let lineEnd := takeLineCommentEnd source (advanceN source start 2)
    match lineEnd.get? with
    | some '\r' => if peekN? source lineEnd 1 == some '\n' then advanceN source lineEnd 2 else advanceN source lineEnd 1
    | some '\n' => advanceN source lineEnd 1
    | _ => lineEnd
  else start

/-- Lex source text into standalone source tokens. -/
def lex (src : String) : Except String (List LexToken) :=
  let source := src.toSlice
  lexFrom source (skipShebang source) []

end LeanRustParser
