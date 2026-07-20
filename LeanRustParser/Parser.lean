module

public import LeanRustParser.Basic.SourceFile
public import LeanRustParser.Lexer

@[expose] public section

namespace LeanRustParser

inductive RustEdition where
  | e2015 | e2018 | e2021 | e2024
  deriving Repr, DecidableEq, BEq

abbrev ParserM := StateT (List LexToken) (Except String)

def parserFail (α : Type) (message : String) : ParserM α := fun _ => .error message

partial def skipTrivia : List LexToken → List LexToken
  | .whitespace _ :: rest | .newline _ :: rest | .lineComment _ :: rest | .blockComment _ :: rest => skipTrivia rest
  | tokens => tokens

def peek : ParserM (Option LexToken) := fun tokens =>
  let tokens := skipTrivia tokens
  .ok (tokens.head?, tokens)

def take : ParserM LexToken := fun tokens =>
  match skipTrivia tokens with
  | token :: rest => .ok (token, rest)
  | [] => .error "unexpected end of Rust input"

def describeLexToken : LexToken → String
  | .keyword keyword => s!"keyword {repr keyword}"
  | .punctuation punctuation => s!"punctuation {repr punctuation}"
  | .ident text _ => s!"identifier '{text.copy}'"
  | .lifetime name _ => s!"lifetime '{name.copy}'"
  | .literal literal => s!"literal '{literal.text.copy}'"
  | .whitespace _ | .newline _ | .lineComment _ | .blockComment _ => "trivia"

def expectKeyword (expected : LexKeyword) : ParserM Unit := do
  match ← take with
  | .keyword actual => if actual == expected then pure () else parserFail Unit s!"expected {repr expected}, found {repr actual}"
  | actual => parserFail Unit s!"expected keyword {repr expected}, found {describeLexToken actual}"

def expectPunctuation (expected : LexPunctuation) : ParserM Unit := do
  match ← take with
  | .punctuation actual => if actual == expected then pure () else parserFail Unit s!"expected {repr expected}, found {repr actual}"
  | actual => parserFail Unit s!"expected punctuation {repr expected}, found {describeLexToken actual}"

def keywordIdent : LexKeyword → Ident
  | .as_ => ⟨"as"⟩ | .async_ => ⟨"async"⟩ | .break_ => ⟨"break"⟩ | .const_ => ⟨"const"⟩
  | .continue_ => ⟨"continue"⟩ | .crate_ => ⟨"crate"⟩ | .default_ => ⟨"default"⟩ | .dyn_ => ⟨"dyn"⟩
  | .else_ => ⟨"else"⟩ | .enum_ => ⟨"enum"⟩ | .extern_ => ⟨"extern"⟩ | .false_ => ⟨"false"⟩
  | .fn_ => ⟨"fn"⟩ | .for_ => ⟨"for"⟩ | .if_ => ⟨"if"⟩ | .impl_ => ⟨"impl"⟩ | .in_ => ⟨"in"⟩
  | .let_ => ⟨"let"⟩ | .loop_ => ⟨"loop"⟩ | .macroRules => ⟨"macro_rules"⟩ | .match_ => ⟨"match"⟩
  | .mod_ => ⟨"mod"⟩ | .move_ => ⟨"move"⟩ | .mut_ => ⟨"mut"⟩ | .pub_ => ⟨"pub"⟩
  | .ref_ => ⟨"ref"⟩ | .return_ => ⟨"return"⟩ | .self_ => ⟨"self"⟩ | .static_ => ⟨"static"⟩
  | .struct_ => ⟨"struct"⟩ | .super_ => ⟨"super"⟩ | .trait_ => ⟨"trait"⟩ | .true_ => ⟨"true"⟩
  | .type_ => ⟨"type"⟩ | .union_ => ⟨"union"⟩ | .unsafe_ => ⟨"unsafe"⟩ | .use_ => ⟨"use"⟩
  | .where_ => ⟨"where"⟩ | .while_ => ⟨"while"⟩

def parseIdent : ParserM Ident := do
  match ← take with
  | .ident text _ => pure ⟨text.copy⟩
  | .keyword keyword => pure (keywordIdent keyword)
  | token => parserFail Ident s!"expected identifier, found {describeLexToken token}"

def mkPath (ident : Ident) : Path := ⟨false, [⟨ident, none⟩]⟩

partial def parsePath : ParserM Path := do
  let global ← match ← peek with | some (.punctuation .pathSep) => expectPunctuation .pathSep; pure true | _ => pure false
  let mut segments := [⟨← parseIdent, none⟩]
  while (← peek) == some (.punctuation .pathSep) do
    expectPunctuation .pathSep
    segments := segments.concat ⟨← parseIdent, none⟩
  pure ⟨global, segments⟩

def litKindOfLex : LexLitKind → LitKind
  | .byte => .byte | .char => .char | .integer => .integer | .float => .float | .str => .str
  | .strRaw hashes => .strRaw hashes | .byteStr => .byteStr | .byteStrRaw hashes => .byteStrRaw hashes
  | .cStr => .cStr | .cStrRaw hashes => .cStrRaw hashes

def parseLiteral : ParserM Lit := do
  match ← take with
  | .literal literal => pure ⟨litKindOfLex literal.kind, literal.text.copy, none⟩
  | .keyword .true_ => pure ⟨.bool, "true", none⟩
  | .keyword .false_ => pure ⟨.bool, "false", none⟩
  | token => parserFail Lit s!"expected literal, found {describeLexToken token}"

mutual
partial def macroTokenTree : ParserM MacroRuleTokenTree := do
  match ← take with
  | .punctuation .openParen => pure (.delimited ⟨.alone, .alone⟩ .parenthesis (← macroTrees .closeParen))
  | .punctuation .openBrace => pure (.delimited ⟨.alone, .alone⟩ .brace (← macroTrees .closeBrace))
  | .punctuation .openBracket => pure (.delimited ⟨.alone, .alone⟩ .bracket (← macroTrees .closeBracket))
  | .ident text raw => pure (.token (.ident text.copy (if raw == .yes then .yes else .no)) .alone)
  | .lifetime text raw => pure (.token (.lifetime text.copy (if raw == .yes then .yes else .no)) .alone)
  | .literal literal => pure (.token (.literal ⟨litKindOfLex literal.kind, literal.text.copy, none⟩) .alone)
  | .keyword keyword => pure (.token (.ident (keywordIdent keyword).name .no) .alone)
  | .punctuation punctuation =>
      let token := match punctuation with
        | .eq => .eq | .lt => .lt | .le => .le | .eqEq => .eqEq | .ne => .ne | .ge => .ge | .gt => .gt
        | .andAnd => .andAnd | .orOr => .orOr | .bang => .bang | .tilde => .tilde | .plus => .plus | .minus => .minus
        | .star => .star | .slash => .slash | .percent => .percent | .caret => .caret | .and => .and | .or => .or
        | .shl => .shl | .shr => .shr | .plusEq => .plusEq | .minusEq => .minusEq | .starEq => .starEq | .slashEq => .slashEq
        | .percentEq => .percentEq | .caretEq => .caretEq | .andEq => .andEq | .orEq => .orEq | .shlEq => .shlEq | .shrEq => .shrEq
        | .at => .at | .dot => .dot | .dotDot => .dotDot | .dotDotDot => .dotDotDot | .dotDotEq => .dotDotEq | .comma => .comma
        | .semi => .semi | .colon => .colon | .pathSep => .pathSep | .rArrow => .rArrow | .lArrow => .lArrow | .fatArrow => .fatArrow
        | .pound => .pound | .dollar => .dollar | .question => .question | .singleQuote => .singleQuote
        | .closeParen | .closeBrace | .closeBracket => .eof
        | .openParen | .openBrace | .openBracket => .eof
      pure (.token token .alone)
  | token => parserFail MacroRuleTokenTree s!"unexpected macro token {describeLexToken token}"

partial def macroTrees (close : LexPunctuation) : ParserM MacroRuleTokenStream := do
  let mut trees := []
  while (← peek) != some (.punctuation close) do
    match ← peek with
    | none => return ← parserFail MacroRuleTokenStream "unclosed macro delimiter"
    | _ => trees := trees.concat (← macroTokenTree)
  expectPunctuation close
  pure trees

partial def parseDelimArgs : ParserM DelimArgs := do
  match ← take with
  | .punctuation .openParen => pure ⟨.parenthesis, ← macroTrees .closeParen⟩
  | .punctuation .openBrace => pure ⟨.brace, ← macroTrees .closeBrace⟩
  | .punctuation .openBracket => pure ⟨.bracket, ← macroTrees .closeBracket⟩
  | token => parserFail DelimArgs s!"expected macro delimiters, found {describeLexToken token}"

partial def parseAttribute : ParserM (Bool × Attribute) := do
  expectPunctuation .pound
  let inner ← match ← peek with | some (.punctuation .bang) => expectPunctuation .bang; pure true | _ => pure false
  expectPunctuation .openBracket
  let path ← parsePath
  let args ← match ← peek with
    | some (.punctuation .eq) => expectPunctuation .eq; pure (.eq ⟨[], .literal (← parseLiteral)⟩)
    | some (.punctuation .openParen) | some (.punctuation .openBrace) | some (.punctuation .openBracket) => pure (.delimited (← parseDelimArgs))
    | _ => pure .empty
  expectPunctuation .closeBracket
  pure (inner, ⟨.normal ⟨.safe, path, args⟩, if inner then .inner else .outer⟩)

partial def parseTy : ParserM Ty := do
  match ← peek with
  | some (.punctuation .and) =>
      expectPunctuation .and
      let mutable ← match ← peek with | some (.keyword .mut_) => expectKeyword .mut_; pure .mut | _ => pure .not
      pure (.ref none ⟨← parseTy, mutable⟩)
  | some (.punctuation .star) =>
      expectPunctuation .star
      let mutable ← match ← peek with | some (.keyword .mut_) => expectKeyword .mut_; pure .mut | some (.keyword .const_) => expectKeyword .const_; pure .not | _ => parserFail Mutability "expected const or mut after *"
      pure (.ptr ⟨← parseTy, mutable⟩)
  | some (.punctuation .openBracket) =>
      expectPunctuation .openBracket
      let ty ← parseTy
      match ← peek with
      | some (.punctuation .semi) => expectPunctuation .semi; let len ← parseExpr; expectPunctuation .closeBracket; pure (.array ty ⟨len⟩)
      | _ => expectPunctuation .closeBracket; pure (.slice ty)
  | some (.punctuation .openParen) =>
      expectPunctuation .openParen
      let mut tys := []
      while (← peek) != some (.punctuation .closeParen) do
        tys := tys.concat (← parseTy)
        if (← peek) == some (.punctuation .comma) then expectPunctuation .comma else pure ()
      expectPunctuation .closeParen
      pure (.tuple tys)
  | some (.punctuation .bang) => expectPunctuation .bang; pure .never
  | some (.keyword .impl_) => expectKeyword .impl_; pure (.implTrait [])
  | some (.keyword .dyn_) => expectKeyword .dyn_; pure (.traitObject [] .dyn_)
  | _ => pure (.path none (← parsePath))

partial def parsePat : ParserM Pat := do
  match ← peek with
  | some (.ident text _) =>
      let ident ← parseIdent
      if text.copy == "_" then pure .wild else pure (.ident ⟨false, .not⟩ ident none)
  | _ => pure (.path none (← parsePath))

partial def parseExpr : ParserM Expr := do
  let atom ← parseAtom
  parseExprSuffix atom

partial def parseAtom : ParserM Expr := do
  match ← peek with
  | some (.literal _) | some (.keyword .true_) | some (.keyword .false_) => pure ⟨[], .literal (← parseLiteral)⟩
  | some (.punctuation .openParen) =>
      expectPunctuation .openParen
      if (← peek) == some (.punctuation .closeParen) then expectPunctuation .closeParen; pure ⟨[], .tuple []⟩ else
      let first ← parseExpr
      match ← peek with
      | some (.punctuation .comma) =>
          let mut xs := [first]
          while (← peek) == some (.punctuation .comma) do
            expectPunctuation .comma
            if (← peek) != some (.punctuation .closeParen) then xs := xs.concat (← parseExpr)
          expectPunctuation .closeParen; pure ⟨[], .tuple xs⟩
      | _ => expectPunctuation .closeParen; pure ⟨[], .paren first⟩
  | some (.punctuation .openBrace) => pure ⟨[], .block (← parseBlock) none⟩
  | some (.punctuation .and) => expectPunctuation .and; pure ⟨[], .addrOf .ref_ .not (← parseExpr)⟩
  | some (.punctuation .star) => expectPunctuation .star; pure ⟨[], .unary .deref (← parseExpr)⟩
  | some (.punctuation .minus) => expectPunctuation .minus; pure ⟨[], .unary .neg (← parseExpr)⟩
  | some (.punctuation .bang) => expectPunctuation .bang; pure ⟨[], .unary .not (← parseExpr)⟩
  | some (.keyword .return_) => expectKeyword .return_; pure ⟨[], .return_ (some (← parseExpr))⟩
  | some (.keyword .break_) => expectKeyword .break_; pure ⟨[], .break_ none none⟩
  | some (.keyword .continue_) => expectKeyword .continue_; pure ⟨[], .continue_ none⟩
  | some (.keyword .if_) => parseIf
  | some (.keyword .loop_) => expectKeyword .loop_; pure ⟨[], .loop_ none (← parseBlock)⟩
  | _ =>
      let path ← parsePath
      match ← peek with
      | some (.punctuation .bang) => expectPunctuation .bang; pure ⟨[], .macCall ⟨path, ← parseDelimArgs⟩⟩
      | _ => pure ⟨[], .path none path⟩

partial def parseExprSuffix (left : Expr) : ParserM Expr := do
  match ← peek with
  | some (.punctuation .openParen) =>
      expectPunctuation .openParen
      let mut args := []
      while (← peek) != some (.punctuation .closeParen) do
        args := args.concat (← parseExpr)
        if (← peek) == some (.punctuation .comma) then expectPunctuation .comma else pure ()
      expectPunctuation .closeParen
      parseExprSuffix ⟨[], .call left args⟩
  | some (.punctuation .dot) => expectPunctuation .dot; let field ← parseIdent; parseExprSuffix ⟨[], .field left field⟩
  | some (.punctuation .question) => expectPunctuation .question; parseExprSuffix ⟨[], .try_ left⟩
  | _ => pure left

partial def parseIf : ParserM Expr := do
  expectKeyword .if_
  let cond ← parseExpr
  let then_ ← parseBlock
  let else_ ← match ← peek with
    | some (.keyword .else_) =>
        expectKeyword .else_
        if (← peek) == some (.keyword .if_) then
          pure (some (← parseIf))
        else
          pure (some ⟨[], .block (← parseBlock) none⟩)
    | _ => pure none
  pure ⟨[], .if_ cond then_ else_⟩

partial def parseBlock : ParserM Block := do
  expectPunctuation .openBrace
  let mut stmts := []
  while (← peek) != some (.punctuation .closeBrace) do
    match ← peek with
    | none => return ← parserFail Block "unclosed block"
    | some (.punctuation .semi) => expectPunctuation .semi; stmts := stmts.concat .empty
    | some (.keyword .let_) =>
        expectKeyword .let_
        let pat ← parsePat
        let ty ← match ← peek with | some (.punctuation .colon) => expectPunctuation .colon; pure (some (← parseTy)) | _ => pure none
        let kind ← match ← peek with | some (.punctuation .eq) => expectPunctuation .eq; pure (.init (← parseExpr)) | _ => pure .decl
        expectPunctuation .semi
        stmts := stmts.concat (.let_ ⟨false, [], pat, ty, kind⟩)
    | _ =>
        let expr ← parseExpr
        if (← peek) == some (.punctuation .semi) then expectPunctuation .semi; stmts := stmts.concat (.semi expr) else stmts := stmts.concat (.expr expr)
  expectPunctuation .closeBrace
  pure ⟨.default_, stmts⟩

partial def emptyGenerics : Generics := ⟨[], ⟨false, []⟩⟩
partial def emptyHeader : FnHeader := ⟨.no, none, .safe, .none⟩

partial def parseFunction (attrs : List Attribute) (vis : Visibility) : ParserM Item := do
  expectKeyword .fn_
  let ident ← parseIdent
  expectPunctuation .openParen
  let mut inputs := []
  while (← peek) != some (.punctuation .closeParen) do
    let pat ← parsePat
    expectPunctuation .colon
    inputs := inputs.concat ⟨[], pat, ← parseTy⟩
    if (← peek) == some (.punctuation .comma) then expectPunctuation .comma else pure ()
  expectPunctuation .closeParen
  let output ← match ← peek with | some (.punctuation .rArrow) => expectPunctuation .rArrow; pure (some (← parseTy)) | _ => pure none
  let body ← match ← peek with | some (.punctuation .openBrace) => pure (some (← parseBlock)) | _ => expectPunctuation .semi; pure none
  pure (.fn_ attrs vis ⟨.implicit, ident, emptyGenerics, ⟨emptyHeader, ⟨inputs, output⟩⟩, none, body⟩)

partial def parseUseTree : ParserM UseTree := do
  let prefix_ ← parsePath
  match ← peek with
  | some (.keyword .as_) => expectKeyword .as_; pure ⟨prefix_, .simple (some (← parseIdent))⟩
  | some (.punctuation .pathSep) =>
      expectPunctuation .pathSep
      match ← peek with
      | some (.punctuation .star) => expectPunctuation .star; pure ⟨prefix_, .glob⟩
      | some (.punctuation .openBrace) =>
          expectPunctuation .openBrace; let mut items := []
          while (← peek) != some (.punctuation .closeBrace) do
            items := items.concat (← parseUseTree)
            if (← peek) == some (.punctuation .comma) then expectPunctuation .comma else pure ()
          expectPunctuation .closeBrace; pure ⟨prefix_, .nested items⟩
      | _ => parserFail UseTree "expected * or { after use path separator"
  | _ => pure ⟨prefix_, .simple none⟩

partial def parseItem (attrs : List Attribute := []) (vis : Visibility := .inherited) : ParserM Item := do
  match ← peek with
  | some (.keyword .pub_) =>
      expectKeyword .pub_
      let visibility ← match ← peek with
        | some (.punctuation .openParen) =>
            expectPunctuation .openParen
            let path ← match ← peek with | some (.keyword .crate_) => expectKeyword .crate_; pure (mkPath ⟨"crate"⟩) | some (.keyword .self_) => expectKeyword .self_; pure (mkPath ⟨"self"⟩) | some (.keyword .super_) => expectKeyword .super_; pure (mkPath ⟨"super"⟩) | some (.keyword .in_) => expectKeyword .in_; parsePath | _ => parserFail Path "expected visibility restriction"
            expectPunctuation .closeParen
            pure (.restricted_ path true)
        | _ => pure .public_
      parseItem attrs visibility
  | some (.keyword .fn_) => parseFunction attrs vis
  | some (.keyword .mod_) =>
      expectKeyword .mod_; let name ← parseIdent
      let kind ← match ← peek with
        | some (.punctuation .openBrace) =>
            expectPunctuation .openBrace
            let (_, items) ← parseItems (some .closeBrace)
            expectPunctuation .closeBrace
            pure (.loaded items .yes)
        | _ => expectPunctuation .semi; pure .unloaded
      pure (.mod attrs vis .safe name kind)
  | some (.keyword .use_) => expectKeyword .use_; let tree ← parseUseTree; expectPunctuation .semi; pure (.use_ attrs vis tree)
  | some (.keyword .macroRules) =>
      expectKeyword .macroRules; expectPunctuation .bang; let name ← parseIdent; let body ← parseDelimArgs
      pure (.macroDef attrs vis name ⟨body, true⟩)
  | some (.ident _ _) =>
      let path ← parsePath
      expectPunctuation .bang
      let args ← parseDelimArgs
      if (← peek) == some (.punctuation .semi) then expectPunctuation .semi else pure ()
      pure (.macro_ attrs vis ⟨path, args⟩)
  | some token => parserFail Item s!"unsupported item starting with {describeLexToken token}"
  | none => parserFail Item "expected an item before end of Rust input"

partial def parseItems (close : Option LexPunctuation := none) : ParserM (List Attribute × List Item) := do
  let mut items := []
  let mut attrs := []
  let mut innerAttrs := []
  while (← peek) != none && (close.isNone || (← peek) != close.map LexToken.punctuation) do
    match ← peek with
    | some (.punctuation .pound) =>
        let (inner, attr) ← parseAttribute
        if inner then innerAttrs := innerAttrs.concat attr else attrs := attrs.concat attr
    | some (.punctuation .semi) => expectPunctuation .semi
    | _ => items := items.concat (← parseItem attrs); attrs := []
  pure (innerAttrs, items)
end

def parseSourceFileTokens : ParserM SourceFile := do
  let (attrs, items) ← parseItems
  pure ⟨none, attrs, items⟩

def parseSourceFile (src : String) (_edition : RustEdition := .e2021) : IO (Except String SourceFile) := do
  pure do
    let tokens ← lex src
    let (sourceFile, remaining) ← parseSourceFileTokens tokens
    match skipTrivia remaining with
    | [] => pure sourceFile
    | token :: _ => .error s!"unexpected trailing Rust token {describeLexToken token}"

end LeanRustParser
