module

/-! Rust concrete lexer.

This is the parser's only source-text boundary.  Like rustc's `token.rs`, it
keeps punctuation, identifiers/literals, and trivia distinct; grammar parsing
can skip trivia while token-tree parsing consumes the exact stream.
-/

@[expose] public section

namespace LeanRustParser

def maxErrorTokenLength : Nat := 120

/-- Parser-facing keyword categories.  These do not occur in macro token
trees, which continue to use `Basic.Token`. -/
inductive LexKeyword where
  | as_ | async_ | break_ | const_ | continue_ | crate_ | default_ | dyn_ | else_
  | enum_ | extern_ | false_ | fn_ | for_ | if_ | impl_ | in_ | let_ | loop_
  | macroRules | match_ | mod_ | move_ | mut_ | pub_ | ref_ | return_ | self_
  | static_ | struct_ | super_ | trait_ | true_ | type_ | union_ | unsafe_ | use_
  | where_ | while_
  deriving Repr, DecidableEq, BEq, Inhabited

/-- Parser-facing punctuation categories. -/
inductive LexPunctuation where
  | eq | lt | le | eqEq | ne | ge | gt | andAnd | orOr | bang | tilde
  | plus | minus | star | slash | percent | caret | and | or | shl | shr
  | plusEq | minusEq | starEq | slashEq | percentEq | caretEq | andEq | orEq | shlEq | shrEq
  | at | dot | dotDot | dotDotDot | dotDotEq | comma | semi | colon | pathSep
  | rArrow | lArrow | fatArrow | pound | dollar | question | singleQuote
  | openParen | closeParen | openBrace | closeBrace | openBracket | closeBracket
  deriving Repr, DecidableEq, BEq, Inhabited

/-- Source-lexer output consumed by the parser.  `LexerToken.raw` retains the
macro-token form so token-tree parsing never loses spacing or raw identifiers. -/
inductive LexToken where
  | keyword (keyword : LexKeyword)
  | punctuation (punctuation : LexPunctuation)
  | ident (text : String) (raw : IdentIsRaw)
  | lifetime (text : String) (raw : IdentIsRaw)
  | literal (literal : Lit)
  | raw (token : Token)
  deriving Repr, DecidableEq, BEq, Inhabited

def lexTokenOfRaw : Token → LexToken
  | .ident text raw => .ident text raw
  | .lifetime text raw => .lifetime text raw
  | .literal literal => .literal literal
  | .eq => .punctuation .eq
  | .lt => .punctuation .lt
  | .gt => .punctuation .gt
  | .bang => .punctuation .bang
  | .plus => .punctuation .plus
  | .minus => .punctuation .minus
  | .star => .punctuation .star
  | .slash => .punctuation .slash
  | .percent => .punctuation .percent
  | .and => .punctuation .and
  | .or => .punctuation .or
  | .comma => .punctuation .comma
  | .semi => .punctuation .semi
  | .colon => .punctuation .colon
  | .question => .punctuation .question
  | .openParen => .punctuation .openParen
  | .closeParen => .punctuation .closeParen
  | .openBrace => .punctuation .openBrace
  | .closeBrace => .punctuation .closeBrace
  | .openBracket => .punctuation .openBracket
  | .closeBracket => .punctuation .closeBracket
  | token => .raw token

def Keyword.ofIdent? : String → Option Keyword
  | "as" => some .as_ | "async" => some .async_ | "break" => some .break_
  | "const" => some .const_ | "continue" => some .continue_ | "crate" => some .crate_
  | "default" => some .default_ | "dyn" => some .dyn_ | "else" => some .else_
  | "enum" => some .enum_ | "extern" => some .extern_ | "false" => some .false_
  | "fn" => some .fn_ | "for" => some .for_ | "if" => some .if_ | "impl" => some .impl_
  | "in" => some .in_ | "let" => some .let_ | "loop" => some .loop_
  | "macro_rules" => some .macroRules | "match" => some .match_ | "mod" => some .mod_
  | "move" => some .move_ | "mut" => some .mut_ | "pub" => some .pub_ | "ref" => some .ref_
  | "return" => some .return_ | "self" => some .self_ | "static" => some .static_
  | "struct" => some .struct_ | "super" => some .super_ | "trait" => some .trait_
  | "true" => some .true_ | "type" => some .type_ | "union" => some .union_
  | "unsafe" => some .unsafe_ | "use" => some .use_ | "where" => some .where_
  | "while" => some .while_ | _ => none

/-- A concrete lexer token together with the spacing information rustc records
between it and the following token.  This is lexer output, not a parser-local
token representation: its `token` field is the exhaustive `Basic.Token.Token`.
-/
structure LexerToken where
  /-- Raw macro-token representation. -/
  token : Token
  /-- Parser-facing lexical category. -/
  lexeme : LexToken := .ident "" .no
  spacing : Spacing
  keyword : Option Keyword := none
  deriving Repr, DecidableEq, BEq, Inhabited

def truncateErrorToken (text : String) : String :=
  if text.length > maxErrorTokenLength then
    (text.take maxErrorTokenLength).toString ++ "…"
  else
    text

def describeToken : Token → String
  | .keyword keyword => s!"keyword '{keyword.spelling}'"
  | .ident text _ => s!"identifier '{truncateErrorToken text}'"
  | .lifetime text _ => s!"lifetime '{truncateErrorToken text}'"
  | .literal lit => s!"literal '{truncateErrorToken lit.symbol}'"
  | token => s!"{repr token}"

def identToken (text : String) : Token :=
  .ident text .no

def singlePunctToken? : Char → Option Token
  | '=' => some .eq | '<' => some .lt | '>' => some .gt | '!' => some .bang
  | '~' => some .tilde | '+' => some .plus | '-' => some .minus | '*' => some .star
  | '/' => some .slash | '%' => some .percent | '^' => some .caret | '&' => some .and
  | '|' => some .or | '@' => some .at | '.' => some .dot | ',' => some .comma
  | ';' => some .semi | ':' => some .colon | '#' => some .pound | '$' => some .dollar
  | '?' => some .question | '\'' => some .singleQuote | '(' => some .openParen
  | ')' => some .closeParen | '{' => some .openBrace | '}' => some .closeBrace
  | '[' => some .openBracket | ']' => some .closeBracket | _ => none

/-- Contextual splitting used by the legacy character-punctuation parser.
The lexer remains maximal-munch; this is the parser operation corresponding to
rustc's `TokenKind::break_two_token_op`. -/
def tokenSplitPunct : Token → Option (List Token)
  | .le => some [.lt, .eq] | .eqEq => some [.eq, .eq] | .ne => some [.bang, .eq]
  | .ge => some [.gt, .eq] | .andAnd => some [.and, .and] | .orOr => some [.or, .or]
  | .shl => some [.lt, .lt] | .shr => some [.gt, .gt]
  | .plusEq => some [.plus, .eq] | .minusEq => some [.minus, .eq] | .starEq => some [.star, .eq]
  | .slashEq => some [.slash, .eq] | .percentEq => some [.percent, .eq] | .caretEq => some [.caret, .eq]
  | .andEq => some [.and, .eq] | .orEq => some [.or, .eq]
  | .shlEq => some [.lt, .lt, .eq] | .shrEq => some [.gt, .gt, .eq]
  | .dotDot => some [.dot, .dot] | .dotDotDot => some [.dot, .dot, .dot] | .dotDotEq => some [.dot, .dot, .eq]
  | .pathSep => some [.colon, .colon] | .rArrow => some [.minus, .gt] | .lArrow => some [.lt, .minus]
  | .fatArrow => some [.eq, .gt]
  | _ => none

def tokenText : Token → String
  | .ident text _ | .lifetime text _ => text
  | .ntIdent ident _ | .ntLifetime ident _ => ident.name
  | .keyword keyword => keyword.spelling
  | .literal lit => lit.symbol
  | .eq => "=" | .lt => "<" | .le => "<=" | .eqEq => "==" | .ne => "!=" | .ge => ">=" | .gt => ">"
  | .andAnd => "&&" | .orOr => "||" | .bang => "!" | .tilde => "~" | .plus => "+" | .minus => "-"
  | .star => "*" | .slash => "/" | .percent => "%" | .caret => "^" | .and => "&" | .or => "|"
  | .shl => "<<" | .shr => ">>" | .plusEq => "+=" | .minusEq => "-=" | .starEq => "*=" | .slashEq => "/="
  | .percentEq => "%=" | .caretEq => "^=" | .andEq => "&=" | .orEq => "|=" | .shlEq => "<<=" | .shrEq => ">>="
  | .at => "@" | .dot => "." | .dotDot => ".." | .dotDotDot => "..." | .dotDotEq => "..="
  | .comma => "," | .semi => ";" | .colon => ":" | .pathSep => "::" | .rArrow => "->" | .lArrow => "<-"
  | .fatArrow => "=>" | .pound => "#" | .dollar => "$" | .question => "?" | .singleQuote => "'"
  | .openParen => "(" | .closeParen => ")" | .openBrace => "{" | .closeBrace => "}" | .openBracket => "[" | .closeBracket => "]"
  | .openInvisible _ | .closeInvisible _ | .eof => ""

def tokenIsWord (token : Token) (expected : String) : Bool :=
  match token with
  | .ident text _ => text == expected
  | _ => false

def tokenIsPunct (token : Token) (expected : Char) : Bool :=
  tokenText token == expected.toString

-- /-- Exact parser patterns over the concrete token union. -/
-- @[match_pattern] def tokenWord (text : String) : Token := .ident text .no
--
-- @[match_pattern] def tokenPunct (c : Char) : Token :=
--   match c with
--   | '=' => .eq | '<' => .lt | '>' => .gt | '!' => .bang | '~' => .tilde
--   | '+' => .plus | '-' => .minus | '*' => .star | '/' => .slash | '%' => .percent
--   | '^' => .caret | '&' => .and | '|' => .or | '@' => .at | '.' => .dot
--   | ',' => .comma | ';' => .semi | ':' => .colon | '#' => .pound | '$' => .dollar
--   | '?' => .question | '\'' => .singleQuote | '(' => .openParen | ')' => .closeParen
--   | '{' => .openBrace | '}' => .closeBrace | '[' => .openBracket | ']' => .closeBracket
--   | _ => .ident c.toString .no

def isIdentStart (c : Char) : Bool :=
  c.isAlpha || c.toNat >= 128 || c == '_'

def isIdentContinue (c : Char) : Bool :=
  isIdentStart c || ('0' <= c && c <= '9')

def isDigit (c : Char) : Bool := '0' <= c && c <= '9'

def isRustWhitespace (c : Char) : Bool :=
  c.isWhitespace || c.toNat == 0x0C || c.toNat == 0x85 ||
    c.toNat == 0x200E || c.toNat == 0x200F || c.toNat == 0x2028 || c.toNat == 0x2029

/-- Advance a validated position without converting the source into a list. -/
def advanceN (source : String.Slice) (pos : source.Pos) : Nat → source.Pos
  | 0 => pos
  | n + 1 =>
      match pos.next? with
      | some next => advanceN source next n
      | none => pos

def peekN? (source : String.Slice) (pos : source.Pos) (n : Nat) : Option Char :=
  (advanceN source pos n).get?

partial def takeWhilePos (source : String.Slice) (pos : source.Pos) (p : Char → Bool) : source.Pos :=
  match pos.get? with
  | some c => if p c then takeWhilePos source (advanceN source pos 1) p else pos
  | none => pos

partial def skipLineComment (source : String.Slice) (pos : source.Pos) : source.Pos :=
  match pos.get? with
  | some '\n' => advanceN source pos 1
  | some _ => skipLineComment source (advanceN source pos 1)
  | none => pos

partial def skipBlockComment (source : String.Slice) (depth : Nat) (pos : source.Pos) : source.Pos :=
  if depth == 0 then pos else
  match pos.get?, peekN? source pos 1 with
  | some '/', some '*' => skipBlockComment source (depth + 1) (advanceN source pos 2)
  | some '*', some '/' => skipBlockComment source (depth - 1) (advanceN source pos 2)
  | some _, _ => skipBlockComment source depth (advanceN source pos 1)
  | none, _ => pos

partial def takeStringEnd (source : String.Slice) (pos : source.Pos) : source.Pos :=
  match pos.get? with
  | some '\\' => takeStringEnd source (advanceN source pos 2)
  | some '"' => advanceN source pos 1
  | some _ => takeStringEnd source (advanceN source pos 1)
  | none => pos

partial def hasHashes (source : String.Slice) (pos : source.Pos) : Nat → Bool
  | 0 => true
  | n + 1 =>
      peekN? source pos 0 == some '#' && hasHashes source (advanceN source pos 1) n

partial def takeRawStringEnd (source : String.Slice) (hashes : Nat) (pos : source.Pos) : source.Pos :=
  match pos.get? with
  | some '"' =>
      let afterQuote := advanceN source pos 1
      if hasHashes source afterQuote hashes then advanceN source afterQuote hashes
      else takeRawStringEnd source hashes (advanceN source pos 1)
  | some _ => takeRawStringEnd source hashes (advanceN source pos 1)
  | none => pos

partial def takeHashes (source : String.Slice) (pos : source.Pos) (count : Nat := 0) : Nat × source.Pos :=
  if pos.get? == some '#' then
    takeHashes source (advanceN source pos 1) (count + 1)
  else
    (count, pos)

def rawStringStart? (source : String.Slice) (pos : source.Pos) : Option (Nat × source.Pos) :=
  if peekN? source pos 0 != some 'r' then none else
  let afterR := advanceN source pos 1
  let (hashes, afterHashes) := takeHashes source afterR
  if afterHashes.get? == some '"' then
    some (hashes, advanceN source afterHashes 1)
  else
    none

/-- Lex punctuation with rustc-style maximal munch, using slice positions. -/
def lexPunct (source : String.Slice) (pos : source.Pos) : Option (Token × source.Pos) :=
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
  | some c, _, _ => (singlePunctToken? c).map fun token => (token, advanceN source pos 1)
  | none, _, _ => none

def emitToken (pendingTrivia : Bool) (token : Token) (acc : List LexerToken) : List LexerToken :=
  let acc :=
    match acc with
    | previous :: rest =>
        { previous with spacing := if !pendingTrivia && token.isPunctuation then .joint else .alone } :: rest
    | [] => []
  let (token, keyword) := match token with
    | .ident text .no =>
        match Keyword.ofIdent? text with
        | some keyword => (.keyword keyword, some keyword)
        | none => (token, none)
    | _ => (token, none)
  { token, spacing := .alone, keyword } :: acc

partial def lexFrom (source : String.Slice) (pos : source.Pos) (pendingTrivia : Bool)
    (acc : List LexerToken) : Except String (List LexerToken) :=
  match pos.get? with
  | none => .ok acc.reverse
  | some c =>
      if isRustWhitespace c then
        let finish := takeWhilePos source pos isRustWhitespace
        lexFrom source finish true acc
      else if c == '/' && peekN? source pos 1 == some '/' then
        lexFrom source (skipLineComment source (advanceN source pos 2)) true acc
      else if c == '/' && peekN? source pos 1 == some '*' then
        lexFrom source (skipBlockComment source 1 (advanceN source pos 2)) true acc
      else if c == 'r' then
        match rawStringStart? source pos with
        | some (hashes, content) =>
            let finish := takeRawStringEnd source hashes content
            lexFrom source finish false (emitToken pendingTrivia (.literal ⟨.strRaw hashes, (source.slice! pos finish).copy, none⟩) acc)
        | none =>
            let finish := takeWhilePos source pos isIdentContinue
            lexFrom source finish false (emitToken pendingTrivia (identToken (source.slice! pos finish).copy) acc)
      else if c == 'b' && peekN? source pos 1 == some '"' then
        let finish := takeStringEnd source (advanceN source pos 2)
        lexFrom source finish false (emitToken pendingTrivia (.literal ⟨.byteStr, (source.slice! pos finish).copy, none⟩) acc)
      else if isDigit c then
        let finish := takeWhilePos source pos isIdentContinue
        lexFrom source finish false (emitToken pendingTrivia (.literal ⟨.integer, (source.slice! pos finish).copy, none⟩) acc)
      else if isIdentStart c then
        let finish := takeWhilePos source pos isIdentContinue
        lexFrom source finish false (emitToken pendingTrivia (identToken (source.slice! pos finish).copy) acc)
      else if c == '"' then
        let finish := takeStringEnd source (advanceN source pos 1)
        lexFrom source finish false (emitToken pendingTrivia (.literal ⟨.str, (source.slice! pos finish).copy, none⟩) acc)
      else
        match lexPunct source pos with
        | some (token, next) => lexFrom source next false (emitToken pendingTrivia token acc)
        | none => .error s!"unsupported Rust character '{c}'"

def stripShebang (src : String) : String :=
  if src.startsWith "#!" && !src.startsWith "#![" && !src.startsWith "#!\n[" && !src.startsWith "#!\r\n[" then
    String.intercalate "\n" ((src.drop 2).toString.splitOn "\n" |>.drop 1)
  else
    src

def lex (src : String) : Except String (List LexerToken) :=
  let source := (stripShebang src).toSlice
  lexFrom source source.startPos false []

end LeanRustParser
