module

public import LeanRustParser.Basic.SourceFile
public import LeanRustParser.Lexer

/-! A deliberately small Rust source parser.  It consumes the concrete token
stream produced by `LeanRustParser.Lexer` and lowers it into the project's Rust
AST without invoking Lean elaboration. -/

@[expose] public section

namespace LeanRustParser

inductive RustEdition where
  | e2015
  | e2018
  | e2021
  | e2024
  deriving Repr, DecidableEq, BEq

abbrev ParserM := StateT (List LexerToken) (Except String)

def fail (α : Type) (message : String) : ParserM α := fun _ => .error message

partial def normalizePunctHead : List LexerToken → List LexerToken
  | lexeme :: rest =>
      match tokenSplitPunct lexeme.token with
      | some tokens => tokens.map (fun token => { token, spacing := lexeme.spacing }) ++ rest
      | none => lexeme :: rest
  | [] => []

partial def skipTrivia : List LexerToken → List LexerToken
  | tokens =>
      match normalizePunctHead tokens with
      | lexeme :: rest => lexeme :: rest
      | [] => []

def peek : ParserM (Option Token) := fun tokens =>
  let tokens := skipTrivia tokens
  .ok (tokens.head?.map (·.token), tokens)

def peekKeyword : ParserM (Option Keyword) := fun tokens =>
  let tokens := skipTrivia tokens
  .ok (tokens.head?.bind (·.keyword), tokens)

def take : ParserM Token := fun tokens =>
  match skipTrivia tokens with
  | lexeme :: rest => .ok (lexeme.token, rest)
  | [] => .error "unexpected end of Rust input"

/-- Take a lexer token without discarding trivia.  Only opaque token-tree
contents use this: all grammatical parsing goes through `take`/`peek`. -/
def takeRaw : ParserM LexerToken := fun tokens =>
  match tokens with
  | lexeme :: rest => .ok (lexeme, rest)
  | [] => .error "unexpected end of Rust input"

def expectToken (expected : Token) : ParserM Unit := do
  let actual ← take
  if actual == expected then pure ()
  else fail Unit s!"expected {describeToken expected}, found {describeToken actual}"

def expectKeyword (expected : Keyword) : ParserM Unit := do
  let tokens ← get
  match skipTrivia tokens with
  | lexeme :: rest =>
      if lexeme.keyword == some expected then set rest
      else fail Unit s!"expected keyword {repr expected}, found {describeToken lexeme.token}"
  | [] => fail Unit s!"expected keyword {repr expected} before end of Rust input"

def expectPunct (expected : Char) : ParserM Unit := do
  let actual ← take
  if tokenIsPunct actual expected then pure ()
  else fail Unit s!"expected '{expected}', found {describeToken actual}"

def expectWord (expected : String) : ParserM Unit := do
  let actual ← take
  if tokenIsWord actual expected then pure ()
  else fail Unit s!"expected '{expected}', found {describeToken actual}"

def parseIdent : ParserM Ident := do
  let token ← take
  match token with
  | .ident value _ => pure (Ident.mk value)
  | _ => fail Ident s!"expected identifier, found {describeToken token}"

def stringLiteralContent (literal : Lit) : Option String :=
  if literal.kind == .str then
    let source := literal.symbol.toSlice
    some <| (source.slice! (advanceN source source.startPos 1) source.endPos.prev!).copy
  else
    none

partial def scopedPathString : ScopedPath → String
  | .self_ => "self"
  | .super_ => "super"
  | .crate_ => "crate"
  | .ident id => id.name
  | .scoped head seg => scopedPathString head ++ "::" ++ seg.name
  | .generic head _ => scopedPathString head
  | .bracketed _ => ""
  | .qpath _ _ seg => seg.name

def literalOfToken (literal : Lit) : Option Literal :=
  let withoutFirstLast (count : Nat := 1) : String :=
    let source := literal.symbol.toSlice
    (source.slice! (advanceN source source.startPos count) source.endPos.prev!).copy
  match literal.kind with
  | .integer => some (.int_ literal.symbol)
  | .float => some (.float_ literal.symbol)
  | .str => stringLiteralContent literal |>.map .str_
  | .strRaw _ => some (.rawStr literal.symbol)
  | .char => some (.char_ (withoutFirstLast))
  | .byte => some (.byte_ (withoutFirstLast 2))
  | .byteStr => some (.byteStr (withoutFirstLast 2))
  | .byteStrRaw _ => some (.rawStr literal.symbol)
  | .cStr => some (.cStr (withoutFirstLast 2))
  | .cStrRaw _ => some (.rawStr literal.symbol)
  | .bool => some (.bool_ (literal.symbol == "true"))
  | .err _ => none

mutual
  partial def parseSourceFileTokens : ParserM SourceFile := do
    let mut items := []
    let mut attrs := []
    let mut sourceAttrs := []
    while (← peek).isSome do
      match ← peek with
      | some (tokenPunct '#') =>
          let (inner, attr) ← parseAttribute
          if inner then
            if !attrs.isEmpty || !items.isEmpty then fail Unit "expected an item after outer attributes"
            sourceAttrs := sourceAttrs.concat attr
          else attrs := attrs.concat attr
      | some (tokenPunct '[') =>
          if !attrs.isEmpty then fail Unit "expected an item after outer attributes"
          expectPunct '['
          let _ ← parseTokenTreeContent ']'
      | some (tokenPunct ';') =>
          if !attrs.isEmpty then fail Unit "expected an item after outer attributes"
          expectPunct ';'
      | some (.keyword .fn_) =>
          items := items.concat (← parseFunction attrs)
          attrs := []
      | some (.keyword .async_) =>
          match ← tryParseQualifiedFunction with
          | some function => items := items.concat function
          | none => fail Unit "expected a qualified function after 'async'"
          attrs := []
      | some (.keyword .macroRules) =>
          items := items.concat (← parseMacroDefinition)
          attrs := []
      | some (.keyword .const_) =>
          match ← tryParseQualifiedFunction with
          | some function => items := items.concat function
          | none =>
              expectKeyword .const_
              match ← peek with
              | some (tokenPunct '{') => items := items.concat (.constBlock (← parseBlock))
              | some (.keyword .trait_) => items := items.concat (← parseTrait)
              | some (.keyword .impl_) => items := items.concat (← parseImpl)
              | _ => items := items.concat (← parseConstItemAfterKeyword attrs)
          attrs := []
      | some (.keyword .type_) =>
          items := items.concat (← parseTypeAlias attrs)
          attrs := []
      | some (.keyword .impl_) =>
          items := items.concat (← parseImpl attrs)
          attrs := []
      | some (.keyword .trait_) =>
          items := items.concat (← parseTrait attrs)
          attrs := []
      | some (.keyword .struct_) =>
          items := items.concat (← parseStruct attrs)
          attrs := []
      | some (.keyword .union_) =>
          items := items.concat (← parseUnion attrs)
          attrs := []
      | some (.keyword .enum_) =>
          items := items.concat (← parseEnum attrs)
          attrs := []
      | some (.keyword .static_) =>
          items := items.concat (← parseStatic attrs)
          attrs := []
      | some (.keyword .mod_) =>
          expectKeyword .mod_
          let name ← parseIdent
          match ← peek with
          | some (tokenPunct '{') =>
              expectPunct '{'
              let body ← parseModuleItems
              expectPunct '}'
              items := items.concat (.mod attrs none name (some body))
          | _ =>
              expectPunct ';'
              items := items.concat (.mod attrs none name none)
          attrs := []
      | some (.keyword .extern_) =>
          expectKeyword .extern_
          match ← peek with
          | some (.keyword .crate_) =>
              expectKeyword .crate_
              let name ← parseIdent
              let alias ←
                match ← peek with
                | some (.keyword .as_) => expectKeyword .as_; pure (some (← parseIdent))
                | _ => pure none
              expectPunct ';'
              items := items.concat (.externCrate attrs none name alias)
          | _ => items := items.concat (← parseExternItem attrs)
          attrs := []
      | some (.keyword .unsafe_) =>
          match ← tryParseQualifiedFunction with
          | some function => items := items.concat function
          | none =>
              expectKeyword .unsafe_
              expectKeyword .extern_
              let mut bodyFound := false
              while !bodyFound do
                match ← peek with
                | some (tokenPunct '{') =>
                    expectPunct '{'
                    let _ ← parseTokenTreeContent '}'
                    bodyFound := true
                | some _ => let _ ← take
                | none => fail Unit "expected a body for unsafe extern"
              items := items.concat (.foreignMod attrs true none [])
          attrs := []
      | some (.keyword .use_) =>
          expectKeyword .use_
          let tree ← parseUseTree
          expectPunct ';'
          items := items.concat (.use_ attrs none tree)
          attrs := []
      | some (.keyword .pub_) =>
          expectKeyword .pub_
          let visibility ←
            match ← peek with
            | some .openParen =>
                expectToken .openParen
                let visibility ←
                  match ← peek with
                  | some (.keyword .crate_) => expectKeyword .crate_; pure .pubCrate
                  | some (.keyword .self_) => expectKeyword .self_; pure .pubSelf
                  | some (.keyword .super_) => expectKeyword .super_; pure .pubSuper
                  | some (.keyword .in_) =>
                      expectKeyword .in_
                      let path ← parseScopedPath
                      pure (.pubIn (scopedPathString path))
                  | some token => fail Visibility s!"expected a visibility scope, found {describeToken token}"
                  | none => fail Visibility "expected a visibility scope"
                expectToken .closeParen
                pure visibility
            | _ => pure .pub
          match ← peek with
          | some (.keyword .fn_) =>
              items := items.concat (← parseFunction attrs (FnModifiers.none) (some visibility))
              attrs := []
          | some (.keyword .const_) =>
              expectKeyword .const_
              match ← peek with
              | some (tokenPunct '{') => items := items.concat (.constBlock (← parseBlock))
              | _ => items := items.concat (← parseConstItemAfterKeyword attrs (some visibility))
              attrs := []
          | some (.keyword .trait_) =>
              items := items.concat (← parseTrait [] (some visibility))
              attrs := []
          | some (.keyword .struct_) =>
              items := items.concat (← parseStruct attrs (some visibility))
              attrs := []
          | some (.keyword .union_) =>
              items := items.concat (← parseUnion attrs (some visibility))
              attrs := []
          | some (.keyword .enum_) =>
              items := items.concat (← parseEnum attrs (some visibility))
              attrs := []
          | some (.keyword .type_) =>
              items := items.concat (← parseTypeAlias attrs (some visibility))
              attrs := []
          | some (.keyword .use_) =>
              expectKeyword .use_
              let tree ← parseUseTree
              expectPunct ';'
              items := items.concat (.use_ attrs (some visibility) tree)
              attrs := []
          | some (.keyword .mod_) =>
              expectKeyword .mod_
              let name ← parseIdent
              match ← peek with
              | some (tokenPunct '{') =>
                  expectPunct '{'
                  let body ← parseModuleItems
                  expectPunct '}'
                  items := items.concat (.mod attrs (some visibility) name (some body))
              | _ =>
                  expectPunct ';'
                  items := items.concat (.mod attrs (some visibility) name none)
              attrs := []
          | some token => fail Unit s!"expected an item after 'pub', found {describeToken token}"
          | none => fail Unit "expected an item after 'pub'"
      | some (.ident _ _) =>
          let name ← parseIdent
          match ← peek with
          | some (tokenPunct '!') =>
              expectPunct '!'
              let tokens ← parseTokenTree
              match ← peek with
              | some (tokenPunct ';') => expectPunct ';'
              | _ => pure ()
              items := items.concat (.macro_ (.mk (.ident name) tokens))
          | _ => fail Unit s!"expected '!' after top-level macro name '{name.name}'"
      | some token => fail Unit s!"expected a Rust item, found {describeToken token}"
      | none => pure ()
    if !attrs.isEmpty then fail Unit "expected an item after outer attributes"
    pure (SourceFile.mk none sourceAttrs items)

  partial def skipUntilSemicolon : ParserM Unit := do
    let mut done := false
    while !done do
      match ← take with
      | tokenPunct ';' => done := true
      | _ => pure ()

  partial def parseModuleItems : ParserM (List Item) := do
    let mut items := []
    let mut attrs := []
    while (← peek) != some (tokenPunct '}') do
      match ← peek with
      | some (tokenPunct '#') =>
          let (_, attr) ← parseAttribute
          attrs := attrs.concat attr
      | some (tokenPunct ';') => expectPunct ';'
      | some (.keyword .fn_) =>
          items := items.concat (← parseFunction attrs)
          attrs := []
      | some (.keyword .struct_) =>
          items := items.concat (← parseStruct attrs)
          attrs := []
      | some (.keyword .union_) =>
          items := items.concat (← parseUnion attrs)
          attrs := []
      | some (.keyword .enum_) =>
          items := items.concat (← parseEnum attrs)
          attrs := []
      | some (.keyword .trait_) =>
          items := items.concat (← parseTrait attrs)
          attrs := []
      | some (.keyword .impl_) =>
          items := items.concat (← parseImpl attrs)
          attrs := []
      | some (.keyword .type_) =>
          items := items.concat (← parseTypeAlias attrs)
          attrs := []
      | some (.keyword .const_) =>
          expectKeyword .const_
          match ← peek with
          | some (tokenPunct '{') => items := items.concat (.constBlock (← parseBlock))
          | _ => items := items.concat (← parseConstItemAfterKeyword attrs)
          attrs := []
      | some (.keyword .use_) =>
          expectKeyword .use_
          let tree ← parseUseTree
          expectPunct ';'
          items := items.concat (.use_ attrs none tree)
          attrs := []
      | some (.keyword .mod_) =>
          expectKeyword .mod_
          let name ← parseIdent
          match ← peek with
          | some (tokenPunct '{') =>
              expectPunct '{'
              let body ← parseModuleItems
              expectPunct '}'
              items := items.concat (.mod attrs none name (some body))
          | _ =>
              expectPunct ';'
              items := items.concat (.mod attrs none name none)
          attrs := []
      | some token => fail Unit s!"expected an item in module, found {describeToken token}"
      | none => fail Unit "expected '}' after module items"
    if !attrs.isEmpty then
      let _ ← fail Unit "expected an item after outer attributes"
      pure ()
    pure items

  partial def skipExternItem : ParserM Unit := do
    let mut done := false
    while !done do
      match ← take with
      | tokenPunct ';' => done := true
      | tokenPunct '{' =>
          let _ ← parseTokenTreeContent '}'
          done := true
      | _ => pure ()

  partial def parseAttribute : ParserM (Bool × Attribute) := do
    expectPunct '#'
    let inner ←
      match ← peek with
      | some (tokenPunct '!') => expectPunct '!'; pure true
      | _ => pure false
    expectPunct '['
    let name ← parseIdent
    let mut path := ScopedPath.ident name
    while (← peek) == some (tokenPunct ':') do
      expectPunct ':'
      expectPunct ':'
      path := .scoped path (← parseIdent)
    let args ←
      match ← peek with
      | some (tokenPunct '(') | some (tokenPunct '[') | some (tokenPunct '{') =>
          let tree ← parseTokenTree
          match tree with
          | .delimited _ delimiter tokens => pure (.unparsed (.delimited ⟨delimiter, tokens⟩))
          | .token _ _ => fail AttrItemKind "expected delimited attribute arguments"
      | some (tokenPunct '=') =>
          expectPunct '='
          pure (.unparsed (.eq (← parseExpr)))
      | some (tokenPunct ':') =>
          expectPunct ':'
          expectPunct ':'
          let _ ← parseIdent
          pure (.unparsed .empty)
      | _ => pure (.unparsed .empty)
    match ← peek with
    | some (tokenPunct ']') => expectPunct ']'
    | _ =>
        if name.name == "cfg" then
          let _ ← parseTokenTreeContent ']'
        else
          match ← peek with
          | some token => fail Unit s!"expected ']' after attribute, found {describeToken token}"
          | none => fail Unit "expected ']' after attribute"
    pure (inner, ⟨.normal ⟨⟨path, args⟩⟩, if inner then .inner else .outer⟩)

  partial def parseTypeParams : ParserM TypeParams := do
    expectPunct '<'
    let mut items := []
    while (← peek) != some (tokenPunct '>') do
      let item ←
        match ← peek with
        | some (tokenPunct '\'') =>
            expectPunct '\''
            let name ← parseIdent
            pure (.lifetime (.mk name.name) none)
        | some (.keyword .const_) =>
            expectKeyword .const_
            let name ← parseIdent
            expectPunct ':'
            let ty ← parseTy
            let default_ ←
              match ← peek with
              | some (tokenPunct '=') =>
                  expectPunct '='
                  match ← peek with
                  | some (.literal literal) =>
                      let _ ← take
                      let value := match literal.kind with
                        | .integer => .int_ literal.symbol
                        | .float => .float_ literal.symbol
                        | .str => .str_ literal.symbol
                        | .byteStr => .byteStr literal.symbol
                        | .char => .char_ literal.symbol
                        | .byte => .byte_ literal.symbol
                        | _ => .str_ literal.symbol
                      pure (some (.literal value))
                  | _ => pure (some (.ident (← parseIdent)))
              | _ => pure none
            pure (.const_ name ty default_)
        | _ =>
            let name ← parseIdent
            let bounds ←
              match ← peek with
              | some (tokenPunct ':') =>
                  expectPunct ':'
                  let mut boundItems := []
                  let mut keepParsing := true
                  while keepParsing do
                    boundItems := boundItems.concat (.trait_ .none [] (← parseTy))
                    match ← peek with
                    | some (tokenPunct '+') => expectPunct '+'
                    | _ => keepParsing := false
                  pure (some (.bounds boundItems))
              | _ => pure none
            let default_ ←
              match ← peek with
              | some (tokenPunct '=') => expectPunct '='; pure (some (← parseTy))
              | _ => pure none
            pure (.ty name bounds default_)
      items := items.concat item
      match ← peek with
      | some (tokenPunct ',') => expectPunct ','
      | some (tokenPunct '>') => pure ()
      | some token => fail Unit s!"expected ',' or '>' in generic parameters, found {describeToken token}"
      | none => fail Unit "expected '>' after generic parameters"
    expectPunct '>'
    pure (.params items)

  partial def parseFunction (attrs : List Attribute) (mods : FnModifiers := FnModifiers.none)
      (vis : Option Visibility := none) : ParserM Item := do
    expectKeyword .fn_
    let name ← parseIdent
    let typeParams ←
      match ← peek with
      | some (tokenPunct '<') => pure (some (← parseTypeParams))
      | _ => pure none
    expectPunct '('
    let mut params := []
    while !(← peek) == some (tokenPunct ')') do
      let param ←
        match ← peek with
        | some (tokenPunct '.') =>
            expectPunct '.'
            expectPunct '.'
            expectPunct '.'
            pure (.variadic none)
        | some (.keyword .self_) =>
            expectKeyword .self_
            match ← peek with
            | some (tokenPunct ':') =>
                expectPunct ':'
                pure (.named false (.ident false false (Ident.mk "self") none) (← parseTy))
            | _ => pure (.self_ false none false)
        | some (.keyword .mut_) =>
            expectKeyword .mut_
            expectKeyword .self_
            match ← peek with
            | some (tokenPunct ':') =>
                expectPunct ':'
                pure (.named true (.ident false false (Ident.mk "self") none) (← parseTy))
            | _ => pure (.self_ false none true)
        | _ =>
            match ← peek with
            | some (tokenPunct '&') =>
                expectPunct '&'
                let lifetime ←
                  match ← peek with
                  | some (tokenPunct '\'') =>
                      expectPunct '\''
                      let name ← parseIdent
                      pure (some (Lifetime.mk name.name))
                  | _ => pure none
                let mutable ←
                  match ← peek with
                  | some (.keyword .mut_) => expectKeyword .mut_; pure true
                  | _ => pure false
                match ← peek with
                | some (.keyword .self_) =>
                    expectKeyword .self_
                    pure (.self_ true lifetime mutable)
                | _ =>
                    let paramName ← parseIdent
                    let paramTy ←
                      match ← peek with
                      | some (tokenPunct ':') => expectPunct ':'; parseTy
                      | _ => pure .implicitSelf
                    pure (.named false (.ident false false paramName none) paramTy)
            | some (tokenPunct '(')
            | some (tokenPunct '[') =>
                let pattern ← parseLetPattern
                let paramTy ←
                  match ← peek with
                  | some (tokenPunct ':') => expectPunct ':'; parseTy
                  | _ => pure .implicitSelf
                pure (.named false pattern paramTy)
            | some (.ident _ _) =>
                let paramName ← parseIdent
                let paramTy ←
                  match ← peek with
                  | some (tokenPunct ':') => expectPunct ':'; parseTy
                  | _ => pure .implicitSelf
                pure (.named false (.ident false false paramName none) paramTy)
            | _ =>
                let _ ← take
                let mut done := false
                while !done do
                  match ← peek with
                  | some (tokenPunct ':') | some (tokenPunct ',') | some (tokenPunct ')') => done := true
                  | some _ => let _ ← take; pure ()
                  | none => done := true
                let paramTy ←
                  match ← peek with
                  | some (tokenPunct ':') => expectPunct ':'; parseTy
                  | _ => pure .implicitSelf
                pure (.named false (.ident false false (Ident.mk "_") none) paramTy)
      params := params.concat param
      match ← peek with
      | some (tokenPunct ',') => expectPunct ','
      | _ => pure ()
    expectPunct ')'
    let returnTy ←
      match ← peek with
      | some (tokenPunct '-') =>
          expectPunct '-'
          expectPunct '>'
          pure (some (← parseTy))
      | _ => pure none
    let body ←
      match ← peek with
      | some (tokenPunct '{') => pure (some (← parseBlock))
      | some (tokenPunct ';') => expectPunct ';'; pure none
      | some _ =>
          while !(← peek) == some (tokenPunct '{') && !(← peek) == some (tokenPunct ';') do
            let _ ← take
          match ← peek with
          | some (tokenPunct '{') => pure (some (← parseBlock))
          | some (tokenPunct ';') => expectPunct ';'; pure none
          | none => fail (Option Block) "expected a function body or ';' before end of Rust input"
          | some _ => fail (Option Block) "unreachable function-body parser state"
      | none => fail (Option Block) "expected a function body or ';'"
    pure (.fn_ attrs vis mods name typeParams params returnTy none body none [])

  partial def parseScopedPath : ParserM ScopedPath := do
    let mut path := ScopedPath.ident (← parseIdent)
    while (← peek) == some (tokenPunct ':') do
      expectPunct ':'
      expectPunct ':'
      path := .scoped path (← parseIdent)
    pure path

  partial def parseUseTree : ParserM UseTree := do
    match ← peek with
    | some (tokenPunct '*') =>
        expectPunct '*'
        pure .glob
    | some (.keyword .self_) =>
        expectKeyword .self_
        pure .self_
    | _ =>
        let name ← parseIdent
        match ← peek with
        | some (.keyword .as_) =>
            expectKeyword .as_
            pure (.alias name (← parseIdent))
        | some (tokenPunct ':') =>
            expectPunct ':'
            expectPunct ':'
            match ← peek with
            | some (tokenPunct '{') =>
                expectPunct '{'
                let mut trees := []
                while (← peek) != some (tokenPunct '}') do
                  trees := trees.concat (← parseUseTree)
                  match ← peek with
                  | some (tokenPunct ',') => expectPunct ','
                  | some (tokenPunct '}') => pure ()
                  | some token => fail Unit s!"expected ',' or '}}' in use tree, found {describeToken token}"
                  | none => fail Unit "expected '}' in use tree"
                expectPunct '}'
                pure (.path name (.list trees))
            | _ => pure (.path name (← parseUseTree))
        | _ => pure (.name name)

  /-- Parse a Rust qualified path, including nested forms such as
  `<<A>::B>::C`.  The concrete lexer has already split `<<` and `>>` only
  where the grammar consumes angle brackets. -/
  partial def parseQualifiedPath : ParserM ScopedPath := do
    expectPunct '<'
    let qself ← parseTy
    let trait_ ←
      match ← peek with
      | some (.keyword .as_) => expectKeyword .as_; pure (some (← parseScopedPath))
      | _ => pure none
    expectPunct '>'
    expectPunct ':'
    expectPunct ':'
    pure (.qpath qself trait_ (← parseIdent))

  partial def parseTy : ParserM Ty := do
    match ← peek with
    | some (tokenPunct '\'') =>
        expectPunct '\''
        let _ ← parseIdent
        pure .err
    | some (tokenPunct '.') =>
        expectPunct '.'
        expectPunct '.'
        expectPunct '.'
        pure .cVarArgs
    | some (tokenPunct '&') =>
        expectPunct '&'
        let lifetime ←
          match ← peek with
          | some (tokenPunct '\'') =>
              expectPunct '\''
              let name ← parseIdent
              pure (some (Lifetime.mk name.name))
          | _ => pure none
        let mut mutable := false
        match ← peek with
        | some (.keyword .mut_) => expectKeyword .mut_; mutable := true
        | _ => pure ()
        pure (.reference lifetime mutable (← parseTy))
    | some (tokenPunct '*') =>
        expectPunct '*'
        let isConst ←
          match ← peek with
          | some (.keyword .const_) => expectKeyword .const_; pure true
          | some (.keyword .mut_) => expectKeyword .mut_; pure false
          | some token => fail Bool s!"expected 'const' or 'mut' after '*', found {describeToken token}"
          | none => fail Bool "expected 'const' or 'mut' after '*'"
        pure (.pointer isConst (← parseTy))
    | some (tokenPunct '[') =>
        expectPunct '['
        let elem ← parseTy
        match ← peek with
        | some (tokenPunct ';') =>
            expectPunct ';'
            let len ← parseExpr
            expectPunct ']'
            pure (.array elem (some len))
        | _ =>
            expectPunct ']'
            pure (.slice elem)
    | some (tokenPunct '<') =>
        pure (.path (← parseQualifiedPath))
    | some (tokenPunct '{') =>
        expectPunct '{'
        let _ ← parseTokenTreeContent '}'
        pure .err
    | some (tokenPunct '(') =>
        expectPunct '('
        let mut elems := []
        if (← peek) != some (tokenPunct ')') then
          elems := elems.concat (← parseTy)
          while (← peek) == some (tokenPunct ',') do
            expectPunct ','
            if (← peek) != some (tokenPunct ')') then
              elems := elems.concat (← parseTy)
        expectPunct ')'
        if elems.isEmpty then pure .unit
        else if elems.length == 1 then pure (.paren elems.head!)
        else pure (.tuple elems)
    | some (.keyword .dyn_) =>
        expectKeyword .dyn_
        let bound ←
          match ← peek with
          | some (tokenPunct '(') =>
              expectPunct '('
              let name ← parseIdent
              expectPunct '('
              let mut params := []
              while (← peek) != some (tokenPunct ')') do
                params := params.concat (.named none (← parseTy))
                match ← peek with
                | some (tokenPunct ',') => expectPunct ','
                | _ => pure ()
              expectPunct ')'
              let ret ←
                match ← peek with
                | some (tokenPunct '-') =>
                    expectPunct '-'; expectPunct '>'
                    pure (some (← parseTy))
                | _ => pure none
              expectPunct ')'
              if name.name == "Fn" then pure (.paren (.fn_ FnModifiers.none params ret))
              else pure (.paren (.named name))
          | some (.ident _ _) =>
              let name ← parseIdent
              match ← peek with
              | some (tokenPunct '(') => expectPunct '('; let _ ← parseTokenTreeContent ')'; pure (.named name)
              | _ => pure (.named name)
          | _ => pure (.named (Ident.mk "dyn"))
        let mut bounds := [.trait_ .none [] bound]
        while (← peek) == some (tokenPunct '+') do
          expectPunct '+'
          match ← peek with
          | some (tokenPunct '\'') =>
              expectPunct '\''
              let lifetime ← parseIdent
              bounds := bounds.concat (.lifetime (.mk lifetime.name))
          | some (.ident _ _) =>
              let name ← parseIdent
              bounds := bounds.concat (.trait_ .none [] (.named name))
          | some (tokenPunct '>') => pure ()
          | _ => fail Unit "expected a trait-object bound after '+'"
        pure (.dynTrait bounds)
    | some (.keyword .impl_) =>
        expectKeyword .impl_
        let mut bounds := []
        let mut keepParsing := true
        while keepParsing do
          match ← peek with
          | some (tokenPunct '\'') =>
              expectPunct '\''
              let name ← parseIdent
              bounds := bounds.concat (.lifetime (.mk name.name))
          | _ => bounds := bounds.concat (.trait_ .none [] (← parseTy))
          match ← peek with
          | some (tokenPunct '+') => expectPunct '+'
          | _ => keepParsing := false
        pure (.implTrait bounds)
    | some (.keyword .fn_) =>
        expectKeyword .fn_
        expectPunct '('
        let mut params := []
        while !(← peek) == some (tokenPunct ')') do
          params := params.concat (.named none (← parseTy))
          match ← peek with
          | some (tokenPunct ',') => expectPunct ','
          | _ => pure ()
        expectPunct ')'
        let ret ←
          match ← peek with
          | some (tokenPunct '-') =>
              expectPunct '-'
              expectPunct '>'
              pure (some (← parseTy))
          | _ => pure none
        pure (.fn_ FnModifiers.none params ret)
    | some (.keyword .extern_) =>
        expectKeyword .extern_
        let abi ←
          match ← peek with
          | some (.literal literal) =>
              match stringLiteralContent literal with
              | some value => let _ ← take; pure value
              | none => fail String s!"expected a string ABI after extern, found {describeToken (.literal literal)}"
          | some token => fail String s!"expected a string ABI after extern, found {describeToken token}"
          | none => fail String "expected a string ABI after extern"
        expectKeyword .fn_
        expectPunct '('
        let mut params := []
        while !(← peek) == some (tokenPunct ')') do
          params := params.concat (.named none (← parseTy))
          match ← peek with
          | some (tokenPunct ',') => expectPunct ','
          | _ => pure ()
        expectPunct ')'
        let ret ←
          match ← peek with
          | some (tokenPunct '-') =>
              expectPunct '-'
              expectPunct '>'
              pure (some (← parseTy))
          | _ => pure none
        pure (.fn_ (.mods none false false false (some (some abi))) params ret)
    | some (.ident _ _) =>
        let mut base := .named (← parseIdent)
        while (← peek) == some (tokenPunct ':') do
          expectPunct ':'
          expectPunct ':'
          base := .named (← parseIdent)
        match ← peek with
        | some (tokenPunct '<') =>
            expectPunct '<'
            let mut args := []
            while !(← peek) == some (tokenPunct '>') do
              args := args.concat (.ty (← parseTy))
              match ← peek with
              | some (tokenPunct ',') => expectPunct ','
              | _ => pure ()
            expectPunct '>'
            pure (.generic base (.args args))
        | _ => pure base
    | some token => fail Ty s!"expected a type, found {describeToken token}"
    | none => fail Ty "expected a type before end of Rust input"

  partial def parseSimpleExpr : ParserM Expr := do
    match ← peek with
    | some (tokenPunct '(') =>
        expectPunct '('
        expectPunct ')'
        pure .unit
    | some (tokenPunct '{') => pure (.block (← parseBlock))
    | _ => parseExpr

  partial def parseConstItem (attrs : List Attribute) : ParserM Item := do
    expectKeyword .const_
    parseConstItemAfterKeyword attrs

  partial def parseConstItemAfterKeyword (attrs : List Attribute) (vis : Option Visibility := none) : ParserM Item := do
    let name ← parseIdent
    expectPunct ':'
    let ty ← parseTy
    let value ←
      match ← peek with
      | some (tokenPunct '=') =>
          expectPunct '='
          pure (some (← parseSimpleExpr))
      | _ => pure none
    expectPunct ';'
    pure (.const_ attrs vis name ty value)

  partial def parseTypeAlias (attrs : List Attribute) (vis : Option Visibility := none) : ParserM Item := do
    expectKeyword .type_
    let name ← parseIdent
    let typeParams ←
      match ← peek with
      | some (tokenPunct '<') => pure (some (← parseTypeParams))
      | _ => pure none
    let mut ty := none
    while !(← peek) == some (tokenPunct ';') do
      match ← peek with
      | some (tokenPunct '=') =>
          expectPunct '='
          ty := some (← parseTy)
      | some _ =>
          let _ ← take
          pure ()
      | none => fail Unit "expected ';' after type alias"
    expectPunct ';'
    pure (.typeAlias attrs vis name typeParams none ty)

  partial def parseStruct (attrs : List Attribute) (vis : Option Visibility := none) : ParserM Item := do
    expectKeyword .struct_
    let name ← parseIdent
    let typeParams ←
      match ← peek with
      | some (tokenPunct '<') => pure (some (← parseTypeParams))
      | _ => pure none
    let mut done := false
    let mut body := .unit
    while !done do
      match ← take with
      | .keyword .as_ => fail Unit "associated-type projections are not valid struct generic parameters"
      | tokenPunct ';' => done := true
      | tokenPunct '{' =>
          let mut fields := []
          while (← peek) != some (tokenPunct '}') do
            let fieldVis ←
              match ← peek with
              | some (.keyword .pub_) => expectKeyword .pub_; pure (some .pub)
              | _ => pure none
            let fieldName ← parseIdent
            expectPunct ':'
            let fieldTy ← parseTy
            fields := fields.concat (.mk [] fieldVis fieldName fieldTy)
            match ← peek with
            | some (tokenPunct ',') => expectPunct ','
            | some (tokenPunct '}') => pure ()
            | some token => fail Unit s!"expected ',' or '}}' after struct field, found {describeToken token}"
            | none => fail Unit "expected '}' after struct fields"
          expectPunct '}'
          body := .record fields
          done := true
      | tokenPunct '(' =>
          let mut fields := []
          while (← peek) != some (tokenPunct ')') do
            let fieldVis ←
              match ← peek with
              | some (.keyword .pub_) => expectKeyword .pub_; pure (some .pub)
              | _ => pure none
            let fieldTy ← parseTy
            fields := fields.concat (.mk [] fieldVis fieldTy)
            match ← peek with
            | some (tokenPunct ',') => expectPunct ','
            | some (tokenPunct ')') => pure ()
            | some token => fail Unit s!"expected ',' or ')' after tuple-struct field, found {describeToken token}"
            | none => fail Unit "expected ')' after tuple-struct fields"
          expectPunct ')'
          expectPunct ';'
          body := .tuple fields
          done := true
      | _ => pure ()
    pure (.struct_ attrs vis name typeParams none body)

  partial def parseUnion (attrs : List Attribute) (vis : Option Visibility := none) : ParserM Item := do
    expectKeyword .union_
    let name ← parseIdent
    let typeParams ←
      match ← peek with
      | some (tokenPunct '<') => pure (some (← parseTypeParams))
      | _ => pure none
    expectPunct '{'
    let mut fields := []
    while (← peek) != some (tokenPunct '}') do
      let fieldVis ←
        match ← peek with
        | some (.keyword .pub_) => expectKeyword .pub_; pure (some .pub)
        | _ => pure none
      let fieldName ← parseIdent
      expectPunct ':'
      let fieldTy ← parseTy
      fields := fields.concat (.mk [] fieldVis fieldName fieldTy)
      match ← peek with
      | some (tokenPunct ',') => expectPunct ','
      | some (tokenPunct '}') => pure ()
      | some token => fail Unit s!"expected ',' or '}}' after union field, found {describeToken token}"
      | none => fail Unit "expected '}' after union fields"
    expectPunct '}'
    pure (.union_ attrs vis name typeParams none fields)

  partial def parseEnum (attrs : List Attribute) (vis : Option Visibility := none) : ParserM Item := do
    expectKeyword .enum_
    let name ← parseIdent
    let typeParams ←
      match ← peek with
      | some (tokenPunct '<') => pure (some (← parseTypeParams))
      | _ => pure none
    while !(← peek) == some (tokenPunct '{') do
      let _ ← take
    expectPunct '{'
    let mut variants := []
    while (← peek) != some (tokenPunct '}') do
      let mut variantAttrs := []
      while (← peek) == some (tokenPunct '#') do
        let (_, attr) ← parseAttribute
        variantAttrs := variantAttrs.concat attr
      let variantName ← parseIdent
      let body ←
        match ← peek with
        | some (tokenPunct '(') =>
            expectPunct '('
            let mut fields := []
            while (← peek) != some (tokenPunct ')') do
              let ty ← parseTy
              fields := fields.concat (.mk [] none ty)
              match ← peek with
              | some (tokenPunct ',') => expectPunct ','
              | some (tokenPunct ')') => pure ()
              | some token => fail Unit s!"expected ',' or ')' after enum tuple field, found {describeToken token}"
              | none => fail Unit "expected ')' after enum tuple fields"
            expectPunct ')'
            pure (.tuple fields)
        | some (tokenPunct '{') =>
            expectPunct '{'
            let mut fields := []
            while (← peek) != some (tokenPunct '}') do
              let fieldName ← parseIdent
              expectPunct ':'
              let fieldTy ← parseTy
              fields := fields.concat (.mk [] none fieldName fieldTy)
              match ← peek with
              | some (tokenPunct ',') => expectPunct ','
              | some (tokenPunct '}') => pure ()
              | some token => fail Unit s!"expected ',' or '}}' after enum record field, found {describeToken token}"
              | none => fail Unit "expected '}' after enum record fields"
            expectPunct '}'
            pure (.record fields)
        | _ => pure .unit
      let disc ←
        match ← peek with
        | some (tokenPunct '=') => expectPunct '='; pure (some (← parseSimpleExpr))
        | _ => pure none
      variants := variants.concat (.mk variantAttrs none variantName body disc)
      match ← peek with
      | some (tokenPunct ',') => expectPunct ','
      | some (tokenPunct '}') => pure ()
      | some token => fail Unit s!"expected ',' or '}}' after enum variant, found {describeToken token}"
      | none => fail Unit "expected '}' after enum variants"
    expectPunct '}'
    pure (.enum_ attrs vis name typeParams none variants)

  partial def parseStatic (attrs : List Attribute) : ParserM Item := do
    expectKeyword .static_
    let mut mutable := false
    match ← peek with
    | some (.keyword .mut_) => expectKeyword .mut_; mutable := true
    | _ => pure ()
    let name ← parseIdent
    expectPunct ':'
    let ty ← parseTy
    let value ←
      match ← peek with
      | some (tokenPunct '=') => expectPunct '='; pure (some (← parseExpr))
      | _ => pure none
    expectPunct ';'
    pure (.static_ attrs none mutable name ty value [])

  partial def parseTrait (attrs : List Attribute := []) (vis : Option Visibility := none) : ParserM Item := do
    expectKeyword .trait_
    let name ← parseIdent
    let typeParams ←
      match ← peek with
      | some (tokenPunct '<') => pure (some (← parseTypeParams))
      | _ => pure none
    let bounds ←
      match ← peek with
      | some (tokenPunct ':') =>
          expectPunct ':'
          let mut items := []
          let mut keepParsing := true
          while keepParsing do
            let modifier ←
              match ← peek with
              | some (tokenPunct '?') => expectPunct '?'; pure .maybe
              | _ => pure .none
            items := items.concat (.trait_ modifier [] (← parseTy))
            match ← peek with
            | some (tokenPunct '+') => expectPunct '+'
            | _ => keepParsing := false
          pure (some (.bounds items))
      | _ => pure none
    while !(← peek) == some (tokenPunct '{') do
      let _ ← take
    expectPunct '{'
    let mut items := []
    while !(← peek) == some (tokenPunct '}') do
      match ← peek with
      | some (tokenPunct '#') =>
          let _ ← parseAttribute
          pure ()
      | some (.keyword .pub_) =>
          expectKeyword .pub_
          match ← peek with
          | some (tokenPunct '(') => let _ ← parseTokenTree; pure ()
          | _ => pure ()
          match ← peek with
          | some (.keyword .fn_) =>
              let function ← parseFunction [] FnModifiers.none (some .pub)
              match function with
              | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
                  items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
              | _ => fail Unit "expected a function item"
          | some (.keyword .type_) =>
              expectKeyword .type_
              let name ← parseIdent
              skipUntilSemicolon
              items := items.concat (.assocType [] name none none none none)
          | some (.keyword .const_) =>
              expectKeyword .const_
              let name ← parseIdent
              expectPunct ':'
              let ty ← parseTy
              skipUntilSemicolon
              items := items.concat (.const_ [] name ty none)
          | some token => fail Unit s!"expected an impl item after 'pub', found {describeToken token}"
          | none => fail Unit "expected an impl item after 'pub'"
      | some (.keyword .const_) =>
          match ← tryParseQualifiedFunction with
          | some function =>
              match function with
              | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
                  items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
              | _ => fail Unit "expected a function item"
          | none =>
              expectKeyword .const_
              let constName ← parseIdent
              expectPunct ':'
              let ty ← parseTy
              let defaultValue ←
                match ← peek with
                | some (tokenPunct '=') =>
                    expectPunct '='
                    pure (some (← parseSimpleExpr))
                | _ => pure none
              expectPunct ';'
              items := items.concat (.const_ [] constName ty defaultValue)
      | some (.keyword .fn_) =>
          let function ← parseFunction []
          match function with
          | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
              items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
          | _ => fail Unit "expected a function item"
      | some (.keyword .type_) =>
          expectKeyword .type_
          let assocName ← parseIdent
          skipUntilSemicolon
          items := items.concat (.assocType [] assocName none none none none)
      | some (.keyword .default_) =>
          expectKeyword .default_
          match ← peek with
          | some (.keyword .fn_) =>
              expectKeyword .fn_
              while !(← peek) == some (tokenPunct '{') && !(← peek) == some (tokenPunct ';') do
                let _ ← take
              match ← peek with
              | some (tokenPunct '{') => expectPunct '{'; let _ ← parseTokenTreeContent '}'; pure ()
              | _ => skipUntilSemicolon
          | _ => skipUntilSemicolon
      | some (.keyword .async_)
      | some (.keyword .unsafe_)
      | some (.keyword .extern_) =>
          let function ← parseQualifiedFunction
          match function with
          | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
              items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
          | _ => fail Unit "expected a function item"
      | some (.ident _ _) =>
          let name ← parseIdent
          expectPunct '!'
          let tokens ← parseTokenTree
          match ← peek with
          | some (tokenPunct ';') => expectPunct ';'
          | _ => pure ()
          items := items.concat (.macro_ (.mk (.ident name) tokens))
      | some token => fail Unit s!"expected a trait item, found {describeToken token}"
      | none => fail Unit "expected a trait item before end of input"
    expectPunct '}'
    pure (.trait_ attrs vis false name typeParams bounds none items)

  partial def parseImpl (attrs : List Attribute := []) : ParserM Item := do
    expectKeyword .impl_
    match ← peek with
    | some (tokenPunct '{') =>
        expectPunct '{'
        let _ ← parseTokenTreeContent '}'
        return (.impl_ [] false none none .err none [])
    | _ => pure ()
    let qualifiedTarget ←
      match ← peek with
      | some (tokenPunct '<') =>
          let tokens ← get
          match parseQualifiedPath tokens with
          | .ok (path, rest) =>
              match (skipTrivia rest).head?.map (·.token) with
              | some (tokenPunct '{') => set rest; pure (some path)
              | _ => pure none
          | .error _ => pure none
      | _ => pure none
    let (traitRef, targetTy) ←
      match qualifiedTarget with
      | some path => pure (none, .path path)
      | none =>
        match ← peek with
        | some (.keyword .dyn_) => pure (none, ← parseTy)
        | _ =>
            let firstTy ← parseTy
            match ← peek with
            | some (.keyword .for_) =>
                expectKeyword .for_
                pure (some (.positive firstTy), ← parseTy)
            | _ => pure (none, firstTy)
    let mut bodyOpened := false
    match ← peek with
    | some (.keyword .where_) =>
        expectKeyword .where_
        let mut previousWasColon := false
        while !bodyOpened do
          match ← take with
          | tokenPunct '{' =>
              if previousWasColon then
                bodyOpened := true
              else
                let _ ← parseTokenTreeContent '}'
                previousWasColon := false
          | tokenPunct ':' => previousWasColon := true
          | _ => previousWasColon := false
    | _ => pure ()
    if !bodyOpened then expectPunct '{'
    let mut items := []
    while !(← peek) == some (tokenPunct '}') do
      match ← peek with
      | some (.keyword .pub_) =>
          expectKeyword .pub_
          match ← peek with
          | some (.keyword .fn_) =>
              let function ← parseFunction [] FnModifiers.none (some .pub)
              match function with
              | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
                  let body := body.getD (.mk none [] none)
                  items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
              | _ => fail Unit "expected a function item"
          | some (.keyword .const_) =>
              expectKeyword .const_
              match ← peek with
              | some (.keyword .fn_) =>
                  let function ← parseFunction [] FnModifiers.none (some .pub)
                  match function with
                  | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
                      let body := body.getD (.mk none [] none)
                      items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
                  | _ => fail Unit "expected a function item"
              | _ =>
                  let name ← parseIdent
                  expectPunct ':'
                  let ty ← parseTy
                  expectPunct '='
                  let value ← parseSimpleExpr
                  expectPunct ';'
                  items := items.concat (.const_ [] (some .pub) name ty value)
          | some token => fail Unit s!"expected an impl item after 'pub', found {describeToken token}"
          | none => fail Unit "expected an impl item after 'pub'"
      | some (.keyword .const_) =>
          match ← tryParseQualifiedFunction with
          | some function =>
              match function with
              | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
                  let body := body.getD (.mk none [] none)
                  items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
              | _ => fail Unit "expected a function item"
          | none =>
              expectKeyword .const_
              let constName ← parseIdent
              expectPunct ':'
              let ty ← parseTy
              let value ←
                match ← peek with
                | some (tokenPunct '=') => expectPunct '='; parseSimpleExpr
                | _ => pure .err
              expectPunct ';'
              items := items.concat (.const_ [] none constName ty value)
      | some (.keyword .fn_) =>
          let function ← parseFunction []
          match function with
          | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
              let body := body.getD (.mk none [] none)
              items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
          | _ => fail Unit "expected a function item"
      | some (.keyword .type_) =>
          expectKeyword .type_
          let name ← parseIdent
          skipUntilSemicolon
          items := items.concat (.assocType [] none name none none none .err)
      | some (.keyword .async_)
      | some (.keyword .unsafe_)
      | some (.keyword .extern_) =>
          let function ← parseQualifiedFunction
          match function with
          | .fn_ attrs visibility mods name tparams params ret where_ body _ _ =>
              let body := body.getD (.mk none [] none)
              items := items.concat (.fn_ attrs visibility mods name tparams params ret where_ body)
          | _ => fail Unit "expected a function item"
      | some token => fail Unit s!"expected an impl item, found {describeToken token}"
      | none => fail Unit "expected an impl item before end of input"
    expectPunct '}'
    pure (.impl_ attrs false none traitRef targetTy none items)

  partial def parseMacroDefinition : ParserM Item := do
    expectKeyword .macroRules
    expectPunct '!'
    let name ← parseIdent
    expectPunct '{'
    let mut rules := []
    while !(← peek) == some (tokenPunct '}') do
      let pattern ← parseTokenTree
      expectPunct '='
      expectPunct '>'
      let body ← parseTokenTree
      match ← peek with
      | some (tokenPunct ';') => expectPunct ';'
      | _ => pure ()
      rules := rules.concat (.mk pattern body)
    expectPunct '}'
    pure (.macroDef name rules)

  partial def parseTokenTree : ParserM TokenTree := do
    let opening ← takeRaw
    match opening.token with
    | tokenPunct '(' =>
        let (tokens, close) ← parseTokenTreeContent ')'
        pure (.delimited ⟨opening.spacing, close⟩ .parenthesis tokens)
    | tokenPunct '[' =>
        let (tokens, close) ← parseTokenTreeContent ']'
        pure (.delimited ⟨opening.spacing, close⟩ .bracket tokens)
    | tokenPunct '{' =>
        let (tokens, close) ← parseTokenTreeContent '}'
        pure (.delimited ⟨opening.spacing, close⟩ .brace tokens)
    | token => fail TokenTree s!"expected a delimited token tree, found {describeToken token}"

  partial def parseTokenTreeContent (closing : Char) : ParserM (TokenStream × Spacing) := do
    let mut trees := []
    let mut done := false
    let mut closeSpacing := Spacing.alone
    while !done do
      let lexeme ← takeRaw
      let token := lexeme.token
      if tokenIsPunct token closing then
        done := true
        closeSpacing := lexeme.spacing
      else if tokenIsPunct token '(' then
        let (tokens, close) ← parseTokenTreeContent ')'
        trees := trees.concat (.delimited ⟨lexeme.spacing, close⟩ .parenthesis tokens)
      else if tokenIsPunct token '[' then
        let (tokens, close) ← parseTokenTreeContent ']'
        trees := trees.concat (.delimited ⟨lexeme.spacing, close⟩ .bracket tokens)
      else if tokenIsPunct token '{' then
        let (tokens, close) ← parseTokenTreeContent '}'
        trees := trees.concat (.delimited ⟨lexeme.spacing, close⟩ .brace tokens)
      else
        trees := trees.concat (.token token lexeme.spacing)
    pure (trees, closeSpacing)

  partial def parseLetPattern : ParserM Pat := do
    match ← peek with
    | some (tokenPunct '[') =>
        expectPunct '['
        let mut patterns := []
        while (← peek) != some (tokenPunct ']') do
          patterns := patterns.concat (← parseLetPattern)
          match ← peek with
          | some (tokenPunct ',') => expectPunct ','
          | some (tokenPunct ']') => pure ()
          | some token => fail Unit s!"expected ',' or ']' in slice pattern, found {describeToken token}"
          | none => fail Unit "expected ']' after slice pattern"
        expectPunct ']'
        pure (.slice patterns)
    | some (tokenPunct '.') =>
        expectPunct '.'
        expectPunct '.'
        pure .rest
    | some (tokenPunct '(') =>
        expectPunct '('
        let mut patterns := []
        if (← peek) != some (tokenPunct ')') then
          patterns := patterns.concat (← parseLetPattern)
          while (← peek) == some (tokenPunct ',') do
            expectPunct ','
            if (← peek) != some (tokenPunct ')') then
              patterns := patterns.concat (← parseLetPattern)
        expectPunct ')'
        pure (if patterns.length == 1 then .paren patterns.head! else .tuple patterns)
    | some (.literal lit) =>
        let _ ← take
        if lit.kind == .integer then
          let lower := RangePat.literal (.int_ lit.symbol)
          match ← peek with
          | some (tokenPunct '.') =>
              expectPunct '.'
              expectPunct '.'
              let inclusive ←
                match ← peek with
                | some (tokenPunct '=') => expectPunct '='; pure true
                | _ => pure false
              let upper ←
                match ← peek with
                | some (tokenPunct '<') => pure (some (.path (← parseQualifiedPath)))
                | some (.ident _ _) => pure (some (.path (← parseScopedPath)))
                | _ => pure none
              pure (.range (some lower) (if inclusive then .inclusive else .exclusive) upper)
          | _ => pure (.literal (.int_ lit.symbol))
        else
          fail Pat s!"expected an integer pattern, found {describeToken (.literal lit)}"
    | some (tokenPunct '<') => pure (.path (← parseQualifiedPath))
    | some (.ident "_" _) => let _ ← take; pure .wildcard
    | some (.ident _ _) =>
        let name ← parseIdent
        match ← peek with
        | some (tokenPunct '{') =>
            expectPunct '{'
            let mut fields := []
            let mut rest := false
            while (← peek) != some (tokenPunct '}') do
              match ← peek with
              | some (tokenPunct '.') =>
                  expectPunct '.'
                  expectPunct '.'
                  fields := fields.concat .remaining
                  rest := true
              | _ =>
                  let field ← parseIdent
                  let value ←
                    match ← peek with
                    | some (tokenPunct ':') => expectPunct ':'; pure (← parseLetPattern)
                    | _ => pure (.ident false false field none)
                  fields := fields.concat (.full false false field value)
              match ← peek with
              | some (tokenPunct ',') => expectPunct ','
              | some (tokenPunct '}') => pure ()
              | some token => fail Unit s!"expected ',' or '}}' after struct pattern field, found {describeToken token}"
              | none => fail Unit "expected '}' after struct pattern"
            expectPunct '}'
            pure (.struct_ (.ident name) fields rest)
        | some (tokenPunct ':') =>
            expectPunct ':'
            expectPunct ':'
            let mut path := ScopedPath.scoped (.ident name) (← parseIdent)
            while (← peek) == some (tokenPunct ':') do
              expectPunct ':'
              expectPunct ':'
              path := .scoped path (← parseIdent)
            match ← peek with
            | some (tokenPunct '(') =>
                expectPunct '('
                let mut pats := []
                while (← peek) != some (tokenPunct ')') do
                  pats := pats.concat (← parseLetPattern)
                  match ← peek with
                  | some (tokenPunct ',') => expectPunct ','
                  | _ => pure ()
                expectPunct ')'
                pure (.tupleStruct path pats)
            | _ => pure (.path path)
        | _ => pure (.ident false false name none)
    | some token => fail Pat s!"expected a let pattern, found {describeToken token}"
    | none => fail Pat "expected a let pattern before end of Rust input"

  /-- Parse a function headed by one or more qualifiers without consuming input
  when the current item is not a function. -/
  partial def tryParseQualifiedFunction : ParserM (Option Item) := do
    let tokens ← get
    match parseQualifiedFunction tokens with
    | .ok (item, rest) => set rest; pure (some item)
    | .error _ => pure none

  partial def parseBlock : ParserM Block := do
    expectPunct '{'
    let mut stmts := []
    let mut pendingAttrs := []
    let mut tail := none
    let mut done := false
    while !done do
      match ← peek with
      | some (tokenPunct '}') =>
          if !pendingAttrs.isEmpty then fail Unit "expected a statement after outer attributes"
          expectPunct '}'
          done := true
      | some (tokenPunct ';') =>
          expectPunct ';'
      | none =>
          fail Unit "expected '}' before end of Rust input"
      | some (tokenPunct '#') =>
          let (_, attr) ← parseAttribute
          pendingAttrs := pendingAttrs.concat attr
      | some (.keyword .return_) =>
          expectKeyword .return_
          let value ←
            match ← peek with
            | some (tokenPunct ';') => pure none
          | _ => pure (some (← parseExpr))
          expectPunct ';'
          stmts := stmts.concat (.semi ⟨pendingAttrs, .return_ value⟩)
          pendingAttrs := []
      | some (.keyword .let_) =>
          expectKeyword .let_
          let mut mutable := false
          match ← peek with
          | some (.keyword .mut_) => expectKeyword .mut_; mutable := true
          | _ => pure ()
          let pattern ← parseLetPattern
          let ty ←
            match ← peek with
            | some (tokenPunct ':') => expectPunct ':'; pure (some (← parseTy))
            | _ => pure none
          let value ←
            match ← peek with
            | some (tokenPunct '=') => expectPunct '='; pure (some (← parseExpr))
            | _ => pure none
          let elseBlock ←
            match ← peek with
            | some (.keyword .else_) => expectKeyword .else_; pure (some (← parseBlock))
            | _ => pure none
          expectPunct ';'
          stmts := stmts.concat (.let_ ⟨pendingAttrs, mutable, pattern, ty, value, elseBlock⟩)
          pendingAttrs := []
      | some (.keyword .pub_) =>
          expectKeyword .pub_
          match ← peek with
          | some (.keyword .fn_) => stmts := stmts.concat (.item (← parseFunction [] FnModifiers.none (some .pub)))
          | some (.keyword .struct_) => stmts := stmts.concat (.item (← parseStruct [] (some .pub)))
          | some (.keyword .union_) => stmts := stmts.concat (.item (← parseUnion [] (some .pub)))
          | some (.keyword .trait_) => stmts := stmts.concat (.item (← parseTrait [] (some .pub)))
          | some (.keyword .const_) =>
              expectKeyword .const_
              match ← peek with
              | some (tokenPunct '{') => stmts := stmts.concat (.item (.constBlock (← parseBlock)))
              | _ => stmts := stmts.concat (.item (← parseConstItemAfterKeyword [] (some .pub)))
          | some token => fail Unit s!"expected an item after 'pub', found {describeToken token}"
          | none => fail Unit "expected an item after 'pub'"
      | some (.keyword .trait_) => stmts := stmts.concat (.item (← parseTrait))
      | some (.keyword .impl_) => stmts := stmts.concat (.item (← parseImpl))
      | some (.keyword .struct_) => stmts := stmts.concat (.item (← parseStruct []))
      | some (.keyword .union_) => stmts := stmts.concat (.item (← parseUnion []))
      | some (.keyword .type_) => stmts := stmts.concat (.item (← parseTypeAlias []))
      | some (.keyword .macroRules) => stmts := stmts.concat (.item (← parseMacroDefinition))
      | some (.keyword .const_) =>
          match ← tryParseQualifiedFunction with
          | some function => stmts := stmts.concat (.item function)
          | none =>
              expectKeyword .const_
              match ← peek with
              | some (tokenPunct '{') => stmts := stmts.concat (.semi (.constBlock (← parseBlock)))
              | some (.keyword .fn_) => stmts := stmts.concat (.item (← parseFunction []))
              | some (.keyword .async_) => stmts := stmts.concat (.item (← parseQualifiedFunction))
              | some (.keyword .unsafe_) => stmts := stmts.concat (.item (← parseQualifiedFunction))
              | some (.keyword .extern_) => stmts := stmts.concat (.item (← parseQualifiedFunction))
              | _ => stmts := stmts.concat (.item (← parseConstItemAfterKeyword []))
      | some (.keyword .fn_) => stmts := stmts.concat (.item (← parseFunction []))
      | some (.keyword .async_) => stmts := stmts.concat (.item (← parseQualifiedFunction))
      | some (.keyword .unsafe_) =>
          match ← tryParseQualifiedFunction with
          | some function => stmts := stmts.concat (.item function)
          | none =>
              expectKeyword .unsafe_
              match ← peek with
              | some (tokenPunct '{') => stmts := stmts.concat (.semi (.unsafeBlock (← parseBlock)))
              | _ => stmts := stmts.concat (.item (← parseFunction []))
      | some (.keyword .extern_) => stmts := stmts.concat (.item (← parseExternInBlock))
      | some (.keyword .mod_) => stmts := stmts.concat (.item (← parseInlineModule))
      | some (.keyword .use_) =>
          expectKeyword .use_
          let tree ← parseUseTree
          expectPunct ';'
          stmts := stmts.concat (.item (.use_ pendingAttrs none tree))
          pendingAttrs := []
      | _ =>
          let expr ← parseExpr
          match ← peek with
          | some (tokenPunct ';') =>
              expectPunct ';'
              let stmt ←
                match expr.kind with
                | .macro_ mac => pure (.macCall ⟨pendingAttrs, mac, .semicolon⟩)
                | _ => pure (.semi { expr with attrs := pendingAttrs })
              stmts := stmts.concat stmt
              pendingAttrs := []
          | some (tokenPunct '}') =>
              tail := some { expr with attrs := pendingAttrs }
              pendingAttrs := []
          | some (tokenPunct '|') =>
              stmts := stmts.concat (.semi { expr with attrs := pendingAttrs })
              pendingAttrs := []
          | some (.keyword .let_) =>
              stmts := stmts.concat (.semi { expr with attrs := pendingAttrs })
              pendingAttrs := []
          | some (.keyword .for_) =>
              stmts := stmts.concat (.semi { expr with attrs := pendingAttrs })
              pendingAttrs := []
          | some .openBrace =>
              -- Block expressions can be statement expressions without a
              -- semicolon when another block statement follows.
              stmts := stmts.concat (.expr { expr with attrs := pendingAttrs })
              pendingAttrs := []
          | some token => fail Unit s!"expected ';' or '}}', found {describeToken token}"
          | none => fail Unit "expected ';' or '}' before end of Rust input"
    pure (.mk none stmts tail)

  partial def parseExternItem (attrs : List Attribute) : ParserM Item := do
    let abi ←
      match ← peek with
      | some (.literal literal) =>
          match stringLiteralContent literal with
          | some abi => let _ ← take; pure (some abi)
          | none => pure none
      | _ => pure none
    match ← peek with
    | some (.keyword .fn_) =>
        parseFunction attrs (.mods none false false false (some abi))
    | some (tokenPunct '{') =>
        parseForeignMod attrs false abi
    | some token => fail Item s!"expected fn or opening brace after extern, found {describeToken token}"
    | none => fail Item "expected fn or opening brace after extern"

  partial def parseForeignMod (attrs : List Attribute) (isUnsafe : Bool) (abi : Option String) : ParserM Item := do
    expectPunct '{'
    let mut items := []
    let mut pendingAttrs := []
    while !(← peek) == some (tokenPunct '}') do
      match ← peek with
      | some (tokenPunct '#') =>
          let (_, attr) ← parseAttribute
          pendingAttrs := pendingAttrs.concat attr
      | some (.keyword .fn_) =>
          let function ← parseFunction pendingAttrs
          match function with
          | .fn_ functionAttrs vis _ name typeParams params ret where_ _ _ _ =>
              items := items.concat (.fn_ functionAttrs vis name typeParams params ret where_)
              pendingAttrs := []
          | _ => fail Unit "expected a foreign function item"
      | some (.keyword .static_) =>
          expectKeyword .static_
          let mutable ←
            match ← peek with
            | some (.keyword .mut_) => expectKeyword .mut_; pure true
            | _ => pure false
          let name ← parseIdent
          expectPunct ':'
          let ty ← parseTy
          expectPunct ';'
          items := items.concat (.static_ pendingAttrs none mutable name ty)
          pendingAttrs := []
      | some (.keyword .type_) =>
          expectKeyword .type_
          let name ← parseIdent
          expectPunct ';'
          items := items.concat (.type_ pendingAttrs none name)
          pendingAttrs := []
      | some (tokenPunct ';') => expectPunct ';'
      | some token => fail Unit s!"unsupported foreign item starting with {describeToken token}"
      | none => fail Unit "expected '}' before end of foreign module"
    if !pendingAttrs.isEmpty then fail Unit "expected a foreign item after outer attributes"
    expectPunct '}'
    pure (.foreignMod attrs isUnsafe abi items)

  partial def parseQualifiedFunction : ParserM Item := do
    let mut ready := false
    let mut coroutine : Option GenBlockKind := none
    let mut const_ := false
    let mut unsafe_ := false
    let mut extern_ : Option (Option String) := none
    while !ready do
      match ← peek with
      | some (.keyword .fn_) => ready := true
      | some (.keyword .async_) => expectKeyword .async_; coroutine := some .async_
      | some (.keyword .unsafe_) => expectKeyword .unsafe_; unsafe_ := true
      | some (.keyword .const_) => expectKeyword .const_; const_ := true
      | some (.keyword .extern_) =>
          expectKeyword .extern_
          let abi ←
            match ← peek with
            | some (.literal literal) =>
                match stringLiteralContent literal with
                | some value => let _ ← take; pure (some value)
                | none => pure none
            | _ => pure none
          extern_ := some abi
      | some token => fail Unit s!"expected a function qualifier, found {describeToken token}"
      | none => fail Unit "expected a function qualifier before end of input"
    parseFunction [] (.mods coroutine const_ unsafe_ false extern_)

  partial def parseExternInBlock : ParserM Item := do
    expectKeyword .extern_
    let abi ←
      match ← peek with
      | some (.literal literal) =>
          match stringLiteralContent literal with
          | some value => let _ ← take; pure (some value)
          | none => pure none
      | _ => pure none
    match ← peek with
    | some (.keyword .fn_) =>
        parseFunction [] (.mods none false false false (some abi))
    | some .openBrace =>
        parseForeignMod [] false abi
    | some token => fail Item s!"expected fn or opening brace after extern, found {describeToken token}"
    | none => fail Item "expected fn or opening brace after extern"

  partial def parseInlineModule : ParserM Item := do
    expectKeyword .mod_
    let name ← parseIdent
    expectPunct '{'
    let items ← parseModuleItems
    expectPunct '}'
    pure (.mod [] none name (some items))

  partial def parseExpr : ParserM Expr := do
    let mut expr ← parsePrimaryExpr
    let mut more := true
    while more do
      match ← peek with
      | some (tokenPunct '+') =>
          expectPunct '+'
          expr := .binary .add expr (← parsePrimaryExpr)
      | some (tokenPunct '-') =>
          expectPunct '-'
          expr := .binary .sub expr (← parsePrimaryExpr)
      | some (tokenPunct '=') =>
          expectPunct '='
          match ← peek with
          | some (tokenPunct '=') =>
              expectPunct '='
              expr := .binary .eq expr (← parsePrimaryExpr)
          | _ => expr := .assign expr (← parseExpr)
      | some (tokenPunct '!') =>
          expectPunct '!'
          expectPunct '='
          expr := .binary .ne expr (← parsePrimaryExpr)
      | some (.keyword .as_) =>
          expectKeyword .as_
          expr := .cast expr (← parseTy)
      | some (tokenPunct '>') =>
          expectPunct '>'
          let op ←
            match ← peek with
            | some (tokenPunct '>') => expectPunct '>'; pure .shr
            | some (tokenPunct '=') => expectPunct '='; pure .ge
            | _ => pure .gt
          expr := .binary op expr (← parsePrimaryExpr)
      | some (tokenPunct '?') =>
          expectPunct '?'
          expr := .try_ expr
      | some (tokenPunct '*') =>
          expectPunct '*'
          let rhs ← parsePrimaryExpr
          expr := match expr with
            | .binary .add left right => .binary .add left (.binary .mul right rhs)
            | .binary .sub left right => .binary .sub left (.binary .mul right rhs)
            | _ => .binary .mul expr rhs
      | some (tokenPunct '/') =>
          expectPunct '/'
          let rhs ← parsePrimaryExpr
          expr := match expr with
            | .binary .add left right => .binary .add left (.binary .div right rhs)
            | .binary .sub left right => .binary .sub left (.binary .div right rhs)
            | _ => .binary .div expr rhs
      | some (tokenPunct '[') =>
          expectPunct '['
          let index ← parseExpr
          expectPunct ']'
          expr := .index expr index
      | some (tokenPunct '(') =>
          expectPunct '('
          let mut args := []
          while !(← peek) == some (tokenPunct ')') do
            args := args.concat (← parseExpr)
            match ← peek with
            | some (tokenPunct ',') => expectPunct ','
            | _ => pure ()
          expectPunct ')'
          expr := .call expr args
      | some (tokenPunct '<') =>
          expectPunct '<'
          let mut typeArgs := []
          while !(← peek) == some (tokenPunct '>') do
            typeArgs := typeArgs.concat (.ty (← parseTy))
            match ← peek with
            | some (tokenPunct ',') => expectPunct ','
            | _ => pure ()
          expectPunct '>'
          expr := .genericFn expr (.args typeArgs)
      | some (tokenPunct ':') =>
          expectPunct ':'
          expectPunct ':'
          match ← peek with
          | some (tokenPunct '<') =>
              expectPunct '<'
              let mut typeArgs := []
              while !(← peek) == some (tokenPunct '>') do
                let arg ←
                  match ← peek with
                  | some (tokenPunct '\'') =>
                      expectPunct '\''
                      let name ← parseIdent
                      pure (.lifetime (.mk name.name))
                  | _ =>
                      let name ← parseIdent
                      match ← peek with
                      | some (tokenPunct '=') =>
                          expectPunct '='
                          pure (.binding name (← parseTy))
                      | some (tokenPunct ':') =>
                          expectPunct ':'
                          let mut bounds := []
                          let mut keepParsing := true
                          while keepParsing do
                            bounds := bounds.concat (.trait_ .none [] (← parseTy))
                            match ← peek with
                            | some (tokenPunct '+') => expectPunct '+'
                            | _ => keepParsing := false
                          pure (.constraint name (.bounds bounds))
                      | _ => pure (.ty (.named name))
                typeArgs := typeArgs.concat arg
                match ← peek with
                | some (tokenPunct ',') => expectPunct ','
                | some (tokenPunct '>') => pure ()
                | some token => fail Unit s!"expected ',' or '>' in generic arguments, found {describeToken token}"
                | none => fail Unit "expected '>' after generic arguments"
              expectPunct '>'
              expr := .genericFn expr (.args typeArgs)
          | some (tokenPunct '(') =>
              expectPunct '('
              let _ ← parseTokenTreeContent ')'
              expr := .genericFn expr (.args [])
          | _ =>
              let segment ← parseIdent
              expr := match expr with
                | .ident head => .path (.scoped (.ident head) segment)
                | .path path => .path (.scoped path segment)
                | _ => .field expr segment
      | some (tokenPunct '.') =>
          expectPunct '.'
          match ← peek with
          | some (tokenPunct '.') =>
              expectPunct '.'
              let inclusive ←
                match ← peek with
                | some (tokenPunct '=') => expectPunct '='; pure true
                | _ => pure false
              let rhs ←
                match ← peek with
                | some (tokenPunct ';') | some (tokenPunct ')') | some (tokenPunct ']') | some (tokenPunct '}') | some (tokenPunct '{') | some (tokenPunct ',') => pure none
                | some (.keyword .if_) => fail (Option Expr) "an `if` expression cannot be a range endpoint without parentheses"
                | _ => pure (some (← parseExpr))
              expr := .range (some expr) (if inclusive then .inclusive else .exclusive) rhs
          | _ =>
              let method ← parseIdent
              match ← peek with
              | some (tokenPunct '(') =>
                  expectPunct '('
                  let mut args := []
                  while !(← peek) == some (tokenPunct ')') do
                    args := args.concat (← parseExpr)
                    match ← peek with
                    | some (tokenPunct ',') => expectPunct ','
                    | _ => pure ()
                  expectPunct ')'
                  expr := .methodCall expr method none args
              | _ => expr := .field expr method
      | _ => more := false
    pure expr

  partial def parseMatch : ParserM Expr := do
    expectKeyword .match_
    let value ← parseExpr
    expectPunct '{'
    let mut arms := []
    while (← peek) != some (tokenPunct '}') do
      let firstPat ← parseLetPattern
      let mut alternatives := [firstPat]
      while (← peek) == some (tokenPunct '|') do
        expectPunct '|'
        alternatives := alternatives.concat (← parseLetPattern)
      let pat := if alternatives.length == 1 then firstPat else .or alternatives
      let guard ←
        match ← peek with
        | some (.keyword .if_) =>
            expectKeyword .if_
            match ← peek with
            | some (.keyword .let_) =>
                expectKeyword .let_
                let guardPat ← parseLetPattern
                expectPunct '='
                pure (some (.let_ guardPat (← parseExpr)))
            | _ => pure (some (.expr (← parseExpr)))
        | _ => pure none
      expectPunct '='
      expectPunct '>'
      let armValue ← parseExpr
      arms := arms.concat ⟨[], pat, guard, armValue⟩
      match ← peek with
      | some (tokenPunct ',') => expectPunct ','
      | some (tokenPunct '}') => pure ()
      | some token => fail Unit s!"expected ',' or '}}' after match arm, found {describeToken token}"
      | none => fail Unit "expected '}' after match arms"
    expectPunct '}'
    pure (.match_ value arms .prefix)

  partial def parsePrimaryExpr : ParserM Expr := do
    match ← peek with
    | some (tokenPunct '!') =>
        expectPunct '!'
        pure (.unary .not (← parsePrimaryExpr))
    | some (tokenPunct '-') =>
        expectPunct '-'
        pure (.unary .neg (← parsePrimaryExpr))
    | some (tokenPunct '*') =>
        expectPunct '*'
        pure (.unary .deref (← parsePrimaryExpr))
    | some (.keyword .break_) =>
        expectKeyword .break_
        let value ←
          match ← peek with
          | some (tokenPunct ';') | some (tokenPunct '}') | some (tokenPunct ')') | some (tokenPunct ',') => pure none
          | _ => pure (some (← parseExpr))
        pure (.break_ none value)
    | some (.keyword .continue_) =>
        expectKeyword .continue_
        pure (.continue_ none)
    | some (.literal lit) =>
        let _ ← take
        match literalOfToken lit with
        | some literal => pure (.literal literal)
        | none => fail Expr s!"expected an expression, found {describeToken (.literal lit)}"
    | some (tokenPunct '<') =>
        pure (.path (← parseQualifiedPath))
    | some (tokenPunct '&') =>
        expectPunct '&'
        let mutable ←
          match ← peek with
          | some (.keyword .mut_) => expectKeyword .mut_; pure true
          | _ => pure false
        pure (.reference false mutable (← parsePrimaryExpr))
    | some (tokenPunct '.') =>
        expectPunct '.'
        expectPunct '.'
        match ← peek with
        | some (tokenPunct '=') =>
            expectPunct '='
            pure (.range none .inclusive (some (← parseExpr)))
        | some (tokenPunct ';') | some (tokenPunct ')') | some (tokenPunct ']') | some (tokenPunct '}') | some (tokenPunct '{') | some (tokenPunct ',') =>
            pure (.range none .exclusive none)
        | some (.keyword .if_) => fail Expr "an `if` expression cannot be a range endpoint without parentheses"
        | _ => pure (.range none .exclusive (some (← parseExpr)))
    | some (tokenPunct '|') =>
        expectPunct '|'
        let mut params := []
        while !(← peek) == some (tokenPunct '|') do
          let name ← parseIdent
          params := params.concat (.pat (.ident false false name none))
          match ← peek with
          | some (tokenPunct ',') => expectPunct ','
          | _ => pure ()
        expectPunct '|'
        pure (.closure false .ref_ params none (.expr (← parseExpr)))
    | some (.keyword .true_) =>
        expectKeyword .true_
        pure (.literal (.bool_ true))
    | some (.keyword .match_) =>
        parseMatch
    | some (.keyword .while_) =>
        expectKeyword .while_
        let condition ← parseExpr
        pure (.while_ none (.expr condition) (← parseBlock))
    | some (.keyword .loop_) =>
        expectKeyword .loop_
        pure (.loop_ none (← parseBlock))
    | some (.keyword .for_) =>
        expectKeyword .for_
        let pat ← parseLetPattern
        expectKeyword .in_
        let iter ← parseExpr
        let body ← parseBlock
        pure (.for_ none pat iter body .for_)
    | some (.keyword .unsafe_) =>
        expectKeyword .unsafe_
        pure (.unsafeBlock (← parseBlock))
    | some (.keyword .if_) => parseIf
    | some (tokenPunct '{') => return .block (← parseBlock)
    | some (tokenPunct '(') =>
        expectPunct '('
        let mut elems := []
        let mut hasComma := false
        while !(← peek) == some (tokenPunct ')') do
          elems := elems.concat (← parseExpr)
          match ← peek with
          | some (tokenPunct ',') =>
              expectPunct ','
              hasComma := true
          | _ => pure ()
        expectPunct ')'
        match elems with
        | [] => pure .unit
        | [e@(.paren (.break_ _ _))] => pure e
        | [e] => pure (if hasComma then .tuple [e] else .paren e)
        | _ => pure (.tuple elems)
    | some (tokenPunct '[') =>
        expectPunct '['
        let mut elems := []
        while !(← peek) == some (tokenPunct ']') do
          elems := elems.concat (← parseExpr)
          match ← peek with
          | some (tokenPunct ',') => expectPunct ','
          | _ => pure ()
        expectPunct ']'
        pure (.array (.list elems))
    | some (.ident _ _) =>
        let name ← parseIdent
        match ← peek with
        | some (tokenPunct '{') =>
            expectPunct '{'
            let mut fields := []
            while (← peek) != some (tokenPunct '}') do
              let field ← parseIdent
              let init ←
                match ← peek with
                | some (tokenPunct ':') =>
                    expectPunct ':'
                    pure (.full field (← parseExpr))
                | _ => pure (.shorthand field)
              fields := fields.concat init
              match ← peek with
              | some (tokenPunct ',') => expectPunct ','
              | some (tokenPunct '}') => pure ()
              | some token => fail Unit s!"expected ',' or '}}' after struct-literal field, found {describeToken token}"
              | none => fail Unit "expected '}' after struct literal"
            expectPunct '}'
            pure (.struct_ (.named name) fields none)
        | some (tokenPunct '!') =>
            expectPunct '!'
            let tokens ← parseTokenTree
            pure (.macro_ (.mk (.ident name) tokens))
        | _ => pure (.ident name)
    | some token => fail Expr s!"expected expression, found {describeToken token}"
    | none => fail Expr "expected expression before end of Rust input"

  partial def parseIf : ParserM Expr := do
    expectKeyword .if_
    let tokens ← get
    let condition ←
      -- Do not let a bare condition such as `if c { ... }` be consumed as
      -- the (invalid here) shorthand struct literal `c { ... }`.
      match skipTrivia tokens with
      | first :: rest =>
          match first.token, (skipTrivia rest).head?.map (·.token) with
          | .ident _ _, some (tokenPunct '{') => pure (.ident (← parseIdent))
          | _, _ => parseExpr
      | [] => parseExpr
    let thenBlock ← parseBlock
    let elseClause ←
      match ← peek with
      | some (.keyword .else_) =>
          expectKeyword .else_
          match ← peek with
          | some (.keyword .if_) => pure (some (.elseIf (← parseIf)))
          | _ => pure (some (.block (← parseBlock)))
      | _ => pure none
    let result := Expr.if_ (.expr condition) thenBlock elseClause
    match ← peek with
    | some (tokenPunct '[') =>
        expectPunct '['
        let index ← parseExpr
        expectPunct ']'
        pure (.index result index)
    | _ => pure result

  partial def parseMacroInvocation : ParserM Expr := do
    let name ← parseIdent
    expectPunct '!'
    let tokens ← parseTokenTree
    pure (.macro_ (.mk (.ident name) tokens))
end

/-- Parse the currently supported Rust source-file subset into `SourceFile`.
The first supported UI fixture is `if-block-unreachable-expr.rs`. -/
def parseSourceFile (src : String) (edition : RustEdition := .e2021) : IO (Except String SourceFile) := do
  pure do
    let tokens ← lex src
    if edition == .e2015 && tokens.any (fun lexeme => tokenIsWord lexeme.token "async") then
      .error "`async` is not available in the Rust 2015 edition"
    else
      let (sourceFile, remaining) ← parseSourceFileTokens tokens
      match skipTrivia remaining with
      | [] => pure sourceFile
      | lexeme :: _ => .error s!"unexpected trailing Rust token {describeToken lexeme.token}"

end LeanRustParser
