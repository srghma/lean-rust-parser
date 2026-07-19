module

-- Rust/PrettyPrinter.lean
-- Pretty-printer for the Rust AST defined in Rust/Basic.lean.
-- Produces indented, source-like Rust output.

public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual
public import LeanRustParser.Basic.SourceFile
public import LeanRustParser.Basic.TokenFunctions
public import LeanRustParser.Doc

@[expose] public section

/-! ──────────────────────────────────────────────────────────────
    § 2  Pretty-printer functions (mutual)
──────────────────────────────────────────────────────────────── -/

def ppLiteral : Literal → Doc
    | .int_    r => Doc.text r
    | .float_  r => Doc.text r
    | .str_    r => Doc.text s!"\"{r}\""
    | .byteStr r => Doc.text s!"b\"{r}\""
    | .cStr    r => Doc.text s!"c\"{r}\""
    | .rawStr  r => Doc.text r
    | .char_   r => Doc.text s!"'{r}'"
    | .byte_   r => Doc.text s!"b'{r}'"
    | .bool_   b => Doc.text (if b then "true" else "false")

def ppIdent (id : Ident) : Doc := Doc.text id.name

def ppLifetime (l : Lifetime) : Doc := Doc.text l.toString

def ppLabel (l : Label) : Doc := Doc.text l.toString

def ppVisibility : Visibility → Doc
    | .inherited => Doc.empty
    | v          => Doc.text v.toString

def ppVisOpt (vis : Option Visibility) : Doc :=
    match vis with
    | none   => Doc.empty
    | some v =>
      let d := ppVisibility v
      if v == .inherited then Doc.empty else d ++ Doc.text " "

def tokenStartsWord : Token → Bool
  | .ident _ _ | .ntIdent _ _ | .lifetime _ _ | .ntLifetime _ _ | .literal _ => true
  | _ => false

def tokenTreeFirstToken? : TokenTree → Option Token
  | .token token _ => some token
  | .delimited _ _ _ => none

def tokenTreeTrailingSpacing : TokenTree → Spacing
  | .token _ spacing => spacing
  | .delimited spacing _ _ => spacing.close

/-- Emit the minimum separator needed for the lexer to reconstruct the same
token boundary and rustc `Spacing`. -/
def ppTokenTreeSeparator (left right : TokenTree) : Doc :=
  let needsSpaceAfter : Token → Bool
    | .rArrow | .comma | .plus | .star | .slash | .percent => true
    | _ => false
  let needsSpaceBefore : Token → Bool
    | .plus | .star | .slash | .percent => true
    | _ => false
  match left, right with
  | .token leftToken _, .delimited _ .parenthesis _ =>
      if leftToken.spelling == "as" then Doc.text " " else Doc.empty
  | _, _ => match left, tokenTreeFirstToken? right with
  | .token leftToken _, some rightToken =>
      if (leftToken == .or && rightToken.spelling != "_") ||
          (leftToken == .colon && rightToken.spelling == "fn") ||
          leftToken.spelling == "as" || rightToken.spelling == "as" ||
          needsSpaceAfter leftToken || needsSpaceBefore rightToken then Doc.text " " else
      if tokenTreeTrailingSpacing left != .alone then Doc.empty else
      if (leftToken.isPunctuation && rightToken.isPunctuation) ||
          (!leftToken.isPunctuation && rightToken.isPunctuation) ||
          (tokenStartsWord leftToken && tokenStartsWord rightToken)
      then Doc.text " " else Doc.empty
    | .delimited _ _ _, some rightToken =>
        if tokenTreeTrailingSpacing left == .alone && rightToken.isPunctuation
        then Doc.text " " else Doc.empty
    | _, none => Doc.empty

def ppDelimiterOpeningSeparator (spacing : Spacing) (tokens : TokenStream) : Doc :=
  if spacing == Spacing.alone && (tokens.head?.bind tokenTreeFirstToken? |>.map Token.isPunctuation |>.getD false)
  then Doc.text " " else Doc.empty

mutual
  partial def ppTokenStream : TokenStream → Doc
    | [] => Doc.empty
    | tree :: rest =>
        ppTokenTree tree ++
        (rest.head?.map (ppTokenTreeSeparator tree) |>.getD Doc.empty) ++
        ppTokenStream rest

  partial def ppTokenTree : TokenTree → Doc
    | .token token _ => Doc.text token.spelling
    | .delimited spacing delimiter tokens =>
        let (open_, close) := match delimiter with
          | .parenthesis => ("(", ")")
          | .brace => ("{", "}")
          | .bracket => ("[", "]")
          | .invisible _ => ("", "")
        match delimiter, tokens with
        | .brace, [] => Doc.text "{}"
        | .brace, [.delimited _ .brace _] =>
            Doc.text open_ ++ ppTokenStream tokens ++ Doc.text close
        | .brace, _ =>
            Doc.braced open_ close (ppTokenStream tokens)
        | _, _ =>
            Doc.text open_ ++ ppDelimiterOpeningSeparator spacing.open_ tokens ++ ppTokenStream tokens ++ Doc.text close
end

def ppMacroRule : MacroRule → Doc
    | .mk pat body =>
        ppTokenTree pat ++ Doc.text " => " ++ ppTokenTree body

def ppUseTree : UseTree → Doc
    | .path seg child  => ppIdent seg ++ Doc.text "::" ++ ppUseTree child
    | .name id         => ppIdent id
    | .alias id a      => ppIdent id ++ Doc.text " as " ++ ppIdent a
    | .glob            => Doc.text "*"
    | .list trees      =>
        Doc.text "{" ++ Doc.commaList (trees.map ppUseTree) ++ Doc.text "}"
    | .self_           => Doc.text "self"

def ppFnModifiers : FnModifiers → Doc
    | .mods coroutine const_ unsafe_ default_ extern_ =>
        (if default_ then Doc.text "default " else Doc.empty) ++
        (if const_   then Doc.text "const "   else Doc.empty) ++
        (match coroutine with
          | none            => Doc.empty
          | some .async_    => Doc.text "async "
          | some .gen       => Doc.text "gen "
          | some .asyncGen  => Doc.text "async gen ") ++
        (if unsafe_  then Doc.text "unsafe "  else Doc.empty) ++
        (match extern_ with
          | none          => Doc.empty
          | some none     => Doc.text "extern \"C\" "
          | some (some a) => Doc.text s!"extern \"{a}\" ")

set_option maxHeartbeats 2000000

mutual

  partial def ppScopedPath : ScopedPath → Doc
    | .self_              => Doc.text "self"
    | .super_             => Doc.text "super"
    | .crate_             => Doc.text "crate"
    | .ident id           => ppIdent id
    | .scoped head seg    => ppScopedPath head ++ Doc.text "::" ++ ppIdent seg
    | .generic head args  => ppScopedPath head ++ Doc.text "::" ++ ppTypeArgs args
    | .bracketed inner    => Doc.text "<" ++ ppTy inner ++ Doc.text ">"
    | .qpath qself trait_ seg =>
        Doc.text "<" ++ ppTy qself ++
        (trait_.map (fun t => Doc.text " as " ++ ppScopedPath t) |>.getD Doc.empty) ++
        Doc.text ">::" ++ ppIdent seg

  partial def ppTypeArgs : TypeArgs → Doc
    | .args []    => Doc.empty
    | .args items =>
        Doc.text "<" ++ Doc.commaList (items.map ppTypeArgItem) ++ Doc.text ">"

  partial def ppTypeArgItem : TypeArgItem → Doc
    | .ty t           => ppTy t
    | .lifetime l     => ppLifetime l
    | .binding n t    => ppIdent n ++ Doc.text " = " ++ ppTy t
    | .assocConst n v => ppIdent n ++ Doc.text " = " ++ ppExpr v
    | .constraint n b => ppIdent n ++ ppTraitBound b
    | .literal lit    => ppLiteral lit
    | .block b        => ppBlock b
    | .infer          => Doc.text "_"

  partial def ppTraitBound : TraitBound → Doc
    | .bounds []    => Doc.empty
    | .bounds items =>
        Doc.text ": " ++ Doc.join (Doc.text " + ") (items.map ppTraitBoundItem)

  partial def ppTraitBoundItem : TraitBoundItem → Doc
    | .trait_ mod forLts t =>
        let modStr := match mod with
          | .none     => ""
          | .maybe    => "?"
          | .maybeConst => "~const "
        let forStr := if forLts.isEmpty then Doc.empty
          else Doc.text "for<" ++ Doc.commaList (forLts.map ppLifetime) ++ Doc.text "> "
        Doc.text modStr ++ forStr ++ ppTy t
    | .lifetime l          => ppLifetime l
    | .use_ args           =>
        Doc.text "use<" ++ Doc.commaList (args.map ppPreciseCapturingArg) ++ Doc.text ">"

  partial def ppPreciseCapturingArg : PreciseCapturingArg → Doc
    | .lifetime l => ppLifetime l
    | .arg p      => ppScopedPath p

  partial def ppBareFnArg : BareFnArg → Doc
    | .named none ty      => ppTy ty
    | .named (some n) ty  => ppIdent n ++ Doc.text ": " ++ ppTy ty
    | .variadic none      => Doc.text "..."
    | .variadic (some n)  => ppIdent n ++ Doc.text ": ..."

  partial def ppTy : Ty → Doc
    | .primitive p     => Doc.text p.toString
    | .named id        => ppIdent id
    | .scoped none name => ppIdent name
    | .scoped (some path) name => ppScopedPath path ++ Doc.text "::" ++ ppIdent name
    | .path sp         => ppScopedPath sp
    | .generic t args  => ppTy t ++ ppTypeArgs args
    | .reference lt mut_ inner =>
        Doc.text "&" ++
        (lt.map (fun l => ppLifetime l ++ Doc.text " ") |>.getD Doc.empty) ++
        (if mut_ then Doc.text "mut " else Doc.empty) ++
        ppTy inner
    | .pinnedRef lt mut_ inner =>
        Doc.text "&pin " ++
        (if mut_ then Doc.text "mut " else Doc.text "const ") ++
        (lt.map (fun l => ppLifetime l ++ Doc.text " ") |>.getD Doc.empty) ++
        ppTy inner
    | .pointer const_ inner =>
        Doc.text (if const_ then "*const " else "*mut ") ++ ppTy inner
    | .array elem none     =>
        Doc.text "[" ++ ppTy elem ++ Doc.text "]"
    | .array elem (some len) =>
        Doc.text "[" ++ ppTy elem ++ Doc.text "; " ++ ppExpr len ++ Doc.text "]"
    | .slice elem          =>
        Doc.text "[" ++ ppTy elem ++ Doc.text "]"
    | .tuple []            => Doc.text "()"
    | .tuple elems         =>
        Doc.text "(" ++ Doc.commaList (elems.map ppTy) ++ Doc.text ")"
    | .unit                => Doc.text "()"
    | .never               => Doc.text "!"
    | .infer               => Doc.text "_"
    | .paren inner         => Doc.text "(" ++ ppTy inner ++ Doc.text ")"
    | .fn_ mods params ret =>
        ppFnModifiers mods ++ Doc.text "fn(" ++ Doc.commaList (params.map ppBareFnArg) ++ Doc.text ")" ++
        (ret.map (fun r => Doc.text " -> " ++ ppTy r) |>.getD Doc.empty)
    | .implTrait bs        =>
        Doc.text "impl " ++ Doc.join (Doc.text " + ") (bs.map ppTraitBoundItem)
    | .dynTrait bs         =>
        Doc.text "dyn " ++ Doc.join (Doc.text " + ") (bs.map ppTraitBoundItem)
    | .unsafeBinder ps inner =>
        Doc.text "unsafe<" ++ ppTypeParamsInner ps ++ Doc.text "> " ++ ppTy inner
    | .pat ty pat          =>
        Doc.text "pattern_type!(" ++ ppTy ty ++ Doc.text " is " ++ ppPat pat ++ Doc.text ")"
    | .fieldOf ty var field =>
        Doc.text "builtin # field_of(" ++ ppTy ty ++
        (var.map (fun v => Doc.text "::" ++ ppIdent v) |>.getD Doc.empty) ++
        Doc.text ", " ++ ppIdent field ++ Doc.text ")"
    | .cVarArgs            => Doc.text "..."
    | .implicitSelf        => Doc.text "Self"
    | .metavar n           => Doc.text n
    | .macro_ inv          => ppMacroInv inv
    | .group inner         => ppTy inner
    | .dummy               => Doc.text "/* dummy */"
    | .err                 => Doc.text "/* error */"

  -- Helper: render the inside of <...> for unsafeBinder
  partial def ppTypeParamsInner : TypeParams → Doc
    | .params items => Doc.commaList (items.map ppTypeParamItem)

  partial def ppBlock : Block → Doc
    | .mk label stmts tail =>
      let lbl := label.map (fun l => ppLabel l ++ Doc.text ": ") |>.getD Doc.empty
      let bodyDocs := stmts.map ppStmt ++ (tail.map ppExpr).toList
      if bodyDocs.isEmpty then
          lbl ++ Doc.text "{}"
      else
          let body := Doc.join Doc.nl bodyDocs
          lbl ++ Doc.braced "{" "}" body

  partial def ppInlineBlock : Block → Doc
    | .mk label stmts tail =>
      let lbl := label.map (fun l => ppLabel l ++ Doc.text ": ") |>.getD Doc.empty
      let bodyDocs := stmts.map ppStmt ++ (tail.map ppExpr).toList
      if bodyDocs.isEmpty then
          lbl ++ Doc.text "{}"
      else
          lbl ++ Doc.text "{ " ++ Doc.join (Doc.text " ") bodyDocs ++ Doc.text " }"

  partial def ppStmt : Stmt → Doc
    | .empty          => Doc.text ";"
    | .expr e         => ppExpr e
    | .semi e         => ppExpr e ++ Doc.text ";"
    | .item it        => ppItem it
    | .macCall stmt =>
        ppAttrs stmt.attrs ++ ppMacroInv stmt.mac ++
        (match stmt.style with | .semicolon => Doc.text ";" | .braces => Doc.empty | .noBraces => Doc.text ";")
    | .let_ local_ =>
        ppAttrs local_.attrs ++ Doc.text "let " ++
        (if local_.mutbl then Doc.text "mut " else Doc.empty) ++
        ppPat local_.pat ++
        (local_.ty.map (fun t => Doc.text ": " ++ ppTy t) |>.getD Doc.empty) ++
        (local_.init.map (fun v => Doc.text " = " ++ ppExpr v) |>.getD Doc.empty) ++
        (local_.else_.map (fun b => Doc.text " else " ++ ppBlock b) |>.getD Doc.empty) ++
        Doc.text ";"

  partial def ppPat : Pat → Doc
    | .literal l          => ppLiteral l
    | .ident ref_ mut_ id bound =>
        (if ref_ then Doc.text "ref " else Doc.empty) ++
        (if mut_ then Doc.text "mut " else Doc.empty) ++
        ppIdent id ++
        (bound.map (fun p => Doc.text " @ " ++ ppPat p) |>.getD Doc.empty)
    | .primitive p        => Doc.text p.toString
    | .path sp            => ppScopedPath sp
    | .tuple pats         =>
        Doc.text "(" ++ Doc.commaList (pats.map ppPat) ++ Doc.text ")"
    | .tupleStruct ty pats =>
        ppScopedPath ty ++ Doc.text "(" ++ Doc.commaList (pats.map ppPat) ++ Doc.text ")"
    | .struct_ ty flds rest =>
        ppScopedPath ty ++ Doc.text " { " ++
        Doc.commaList (flds.map ppFieldPat) ++
        (if rest then Doc.text (if flds.isEmpty then ".." else ", ..") else Doc.empty) ++
        Doc.text " }"
    | .slice pats         =>
        Doc.text "[" ++ Doc.commaList (pats.map ppPat) ++ Doc.text "]"
    | .reference mut_ inner =>
        Doc.text "&" ++ (if mut_ then Doc.text "mut " else Doc.empty) ++ ppPat inner
    | .range lo op hi     =>
        (lo.map ppRangePat |>.getD Doc.empty) ++
        Doc.text op.toString ++
        (hi.map ppRangePat |>.getD Doc.empty)
    | .or alts            => Doc.join (Doc.text " | ") (alts.map ppPat)
    | .box_ inner         => Doc.text "box " ++ ppPat inner
    | .deref inner        => Doc.text "deref!(" ++ ppPat inner ++ Doc.text ")"
    | .never              => Doc.text "!"
    | .paren inner        => Doc.text "(" ++ ppPat inner ++ Doc.text ")"
    | .guard pat cond     => ppPat pat ++ Doc.text " if " ++ ppExpr cond
    | .rest               => Doc.text ".."
    | .wildcard           => Doc.text "_"
    | .constBlock b       => Doc.text "const " ++ ppBlock b
    | .macro_ inv         => ppMacroInv inv
    | .err                => Doc.text "/* pat error */"

  partial def ppRangePat : RangePat → Doc
    | .literal l => ppLiteral l
    | .path p    => ppScopedPath p

  partial def ppFieldPat : FieldPat → Doc
    | .shorthand ref_ mut_ name =>
        (if ref_ then Doc.text "ref " else Doc.empty) ++
        (if mut_ then Doc.text "mut " else Doc.empty) ++
        ppIdent name
    | .full ref_ mut_ name pat =>
        (if ref_ then Doc.text "ref " else Doc.empty) ++
        (if mut_ then Doc.text "mut " else Doc.empty) ++
        ppIdent name ++ Doc.text ": " ++ ppPat pat
    | .remaining => Doc.text ".."

  partial def ppExpr : Expr → Doc
    | .mk attrs kind => ppAttrs attrs ++ ppExprKind kind

  partial def ppExprKind : ExprKind → Doc
    | .literal l         => ppLiteral l
    | .ident id          => ppIdent id
    | .primitive p       => Doc.text p.toString
    | .self_             => Doc.text "self"
    | .path sp           => ppScopedPath sp
    | .metavar n         => Doc.text n
    | .infer             => Doc.text "_"
    | .unary op e        => Doc.text op.toString ++ ppExpr e
    | .binary op l r     =>
        ppExpr l ++ Doc.text s!" {op.toString} " ++ ppExpr r
    | .assign l r        => ppExpr l ++ Doc.text " = " ++ ppExpr r
    | .compoundAssign op l r =>
        ppExpr l ++ Doc.text s!" {op.toString} " ++ ppExpr r
    | .cast e ty         => ppExpr e ++ Doc.text " as " ++ ppTy ty
    | .type_ e ty        => ppExpr e ++ Doc.text ": " ++ ppTy ty
    | .try_ e            => ppExpr e ++ Doc.text "?"
    | .range none op none   => Doc.text op.toString
    | .range (some lo) op none  => ppExpr lo ++ Doc.text op.toString
    | .range none op (some hi)  => Doc.text op.toString ++ ppExpr hi
    | .range (some lo) op (some hi) =>
        ppExpr lo ++ Doc.text op.toString ++ ppExpr hi
    | .range_            => Doc.text ".."
    | .call fn_ args     =>
        ppExpr fn_ ++ Doc.text "(" ++ Doc.commaList (args.map ppExpr) ++ Doc.text ")"
    | .methodCall recv method turbo args =>
        ppExpr recv ++ Doc.text "." ++ ppIdent method ++
        (turbo.map (fun t => Doc.text "::" ++ ppTypeArgs t) |>.getD Doc.empty) ++
        Doc.text "(" ++ Doc.commaList (args.map ppExpr) ++ Doc.text ")"
    | .field recv fld    => ppExpr recv ++ Doc.text "." ++ ppIdent fld
    | .tupleField recv idx => ppExpr recv ++ Doc.text s!".{idx}"
    | .index recv idx    =>
        ppExpr recv ++ Doc.text "[" ++ ppExpr idx ++ Doc.text "]"
    | .await e           => ppExpr e ++ Doc.text ".await"
    | .move_ e           => Doc.text "move(" ++ ppExpr e ++ Doc.text ")"
    | .become e          => Doc.text "become " ++ ppExpr e
    | .yeet none         => Doc.text "do yeet"
    | .yeet (some e)     => Doc.text "do yeet " ++ ppExpr e
    | .closure async_ capture params ret body =>
        (if async_ then Doc.text "async " else Doc.empty) ++
        (match capture with
          | .value => Doc.text "move "
          | .use_  => Doc.text "use "
          | .ref_  => Doc.empty) ++
        Doc.text "|" ++ Doc.commaList (params.map ppClosureParam) ++ Doc.text "|" ++
        (ret.map (fun t => Doc.text " -> " ++ ppTy t) |>.getD Doc.empty) ++
        Doc.text " " ++ ppClosureBody body
    | .block b           => ppInlineBlock b
    | .unsafeBlock b     => Doc.text "unsafe " ++ ppInlineBlock b
    | .genBlock capture b kind =>
        (match kind with
          | .async_    => Doc.text "async "
          | .gen       => Doc.text "gen "
          | .asyncGen  => Doc.text "async gen ") ++
        (match capture with
          | .value => Doc.text "move "
          | .use_  => Doc.text "use "
          | .ref_  => Doc.empty) ++
        ppInlineBlock b
    | .tryBlock b _ty     => Doc.text "try " ++ ppInlineBlock b
    | .constBlock b      => Doc.text "const " ++ ppInlineBlock b
    | .if_ cond then_ else_ =>
        Doc.text "if " ++ ppCondition cond ++ Doc.text " " ++ ppInlineBlock then_ ++
        (else_.map (fun e => Doc.text " " ++ ppElseClause e) |>.getD Doc.empty)
    | .match_ val arms kind =>
        (match kind with | .prefix => Doc.empty | .postfix => ppExpr val ++ Doc.text ".") ++
        Doc.text "match " ++
        (match kind with | .prefix => ppExpr val | .postfix => Doc.empty) ++
        Doc.text " " ++
        Doc.braced "{" "}" (Doc.join Doc.nl (arms.map ppMatchArm))
    | .while_ lbl cond body =>
        (lbl.map (fun l => ppLabel l ++ Doc.text ": ") |>.getD Doc.empty) ++
        Doc.text "while " ++ ppCondition cond ++ Doc.text " " ++ ppInlineBlock body
    | .loop_ lbl body =>
        (lbl.map (fun l => ppLabel l ++ Doc.text ": ") |>.getD Doc.empty) ++
        Doc.text "loop " ++ ppInlineBlock body
    | .for_ lbl pat iter body kind =>
        (lbl.map (fun l => ppLabel l ++ Doc.text ": ") |>.getD Doc.empty) ++
        (match kind with | .for_ => Doc.text "for " | .forAwait => Doc.text "for await ") ++
        ppPat pat ++ Doc.text " in " ++ ppExpr iter ++ Doc.text " " ++ ppInlineBlock body
    | .return_ none      => Doc.text "return"
    | .return_ (some v)  => Doc.text "return " ++ ppExpr v
    | .yield_ none kind  =>
        match kind with | .prefix => Doc.text "yield" | .postfix => Doc.text ".yield"
    | .yield_ (some v) kind =>
        match kind with
        | .prefix  => Doc.text "yield " ++ ppExpr v
        | .postfix => ppExpr v ++ Doc.text ".yield"
    | .break_ lbl val    =>
        Doc.text "break" ++
        (lbl.map (fun l => Doc.text s!" {l.toString}") |>.getD Doc.empty) ++
        (val.map (fun v => Doc.text " " ++ ppExpr v) |>.getD Doc.empty)
    | .continue_ lbl     =>
        Doc.text "continue" ++
        (lbl.map (fun l => Doc.text s!" {l.toString}") |>.getD Doc.empty)
    | .use_ e            => ppExpr e ++ Doc.text ".use"
    | .array (.list elems) =>
        Doc.text "[" ++ Doc.commaList (elems.map ppExpr) ++ Doc.text "]"
    | .array (.repeat e len) =>
        Doc.text "[" ++ ppExpr e ++ Doc.text "; " ++ ppExpr len ++ Doc.text "]"
    | .tuple elems       =>
        match elems with
        | [elem] => Doc.text "(" ++ ppExpr elem ++ Doc.text ",)"
        | _ => Doc.text "(" ++ Doc.commaList (elems.map ppExpr) ++ Doc.text ")"
    | .unit              => Doc.text "()"
    | .struct_ name flds base =>
        ppStructExprName name ++ Doc.text " { " ++
        Doc.commaList (flds.map ppFieldInit) ++
        (base.map (fun e => Doc.text (if flds.isEmpty then ".." else ", ..") ++ ppExpr e)
          |>.getD Doc.empty) ++
        Doc.text " }"
    | .paren e           => Doc.text "(" ++ ppExpr e ++ Doc.text ")"
    | .genericFn fn_ args =>
        ppExpr fn_ ++ Doc.text "::" ++ ppTypeArgs args
    | .macro_ inv        => ppMacroInv inv
    | .formatArgs tt     => Doc.text "format_args!" ++ ppTokenTree tt
    | .inlineAsm asm     => ppInlineAsm asm
    | .offsetOf ty fields =>
        Doc.text "offset_of!(" ++ ppTy ty ++ Doc.text ", " ++
        Doc.commaList (fields.map ppIdent) ++ Doc.text ")"
    | .includedBytes path => Doc.text s!"include_bytes!(\"{path}\")"
    | .reference raw mut_ e =>
        Doc.text "&" ++
        (if raw then Doc.text "raw " else Doc.empty) ++
        (if mut_ then Doc.text "mut " else Doc.text "") ++
        ppExpr e
    | .unsafeBinderCast kind e ty =>
        let kw := match kind with | .wrap => "unsafe_binder_wrap!" | .unwrap => "unsafe_binder_unwrap!"
        Doc.text kw ++ Doc.text "(" ++ ppExpr e ++
        (ty.map (fun t => Doc.text ", " ++ ppTy t) |>.getD Doc.empty) ++
        Doc.text ")"
    | .dummy             => Doc.text "/* dummy */"
    | .err               => Doc.text "/* error */"

  partial def ppCondition : Condition → Doc
    | .expr e           => ppExpr e
    | .let_ pat val     => Doc.text "let " ++ ppPat pat ++ Doc.text " = " ++ ppExpr val
    | .letChain items   =>
        Doc.join (Doc.text " && ") (items.map fun
          | .expr e       => ppExpr e
          | .let_ pat val => Doc.text "let " ++ ppPat pat ++ Doc.text " = " ++ ppExpr val)

  partial def ppElseClause : ElseClause → Doc
    | .block b  => Doc.text "else " ++ ppInlineBlock b
    | .elseIf e => Doc.text "else " ++ ppExpr e

  partial def ppMatchArm : MatchArm → Doc
    | .mk _attrs pat guard val =>
        ppPat pat ++
        (guard.map (fun g => Doc.text " if " ++ ppCondition g) |>.getD Doc.empty) ++
        Doc.text " => " ++ ppExpr val ++ Doc.text ","

  partial def ppClosureParam : ClosureParam → Doc
    | .pat p       => ppPat p
    | .typed p ty  => ppPat p ++ Doc.text ": " ++ ppTy ty

  partial def ppClosureBody : ClosureBody → Doc
    | .expr e  => ppExpr e
    | .block b => ppBlock b
    | .hole    => Doc.text "_"

  partial def ppStructExprName : StructExprName → Doc
    | .named id          => ppIdent id
    | .scoped sp n       => ppScopedPath sp ++ Doc.text "::" ++ ppIdent n
    | .turbofish id args => ppIdent id ++ Doc.text "::" ++ ppTypeArgs args
    | .qpath q tr seg    =>
        Doc.text "<" ++ ppTy q ++
        (tr.map (fun t => Doc.text " as " ++ ppScopedPath t) |>.getD Doc.empty) ++
        Doc.text ">::" ++ ppIdent seg

  partial def ppFieldInit : FieldInit → Doc
    | .shorthand id    => ppIdent id
    | .full field val  => ppIdent field ++ Doc.text ": " ++ ppExpr val

  partial def ppMacroInv : MacroInvocation → Doc
    | .mk path tt =>
        ppScopedPath path ++ Doc.text "!" ++ ppTokenTree tt

  partial def ppInlineAsm : InlineAsm → Doc
    | .mk template _operands =>
        Doc.text "asm!(" ++ Doc.commaList (template.map Doc.text) ++ Doc.text ")"

  partial def ppParam : Param → Doc
    | .named mut_ pat ty =>
        (if mut_ then Doc.text "mut " else Doc.empty) ++
        ppPat pat ++ Doc.text ": " ++ ppTy ty
    | .self_ ref_ lt mut_ =>
        (if ref_ then Doc.text "&" else Doc.empty) ++
        (lt.map (fun l => ppLifetime l ++ Doc.text " ") |>.getD Doc.empty) ++
        (if mut_ then Doc.text "mut " else Doc.empty) ++
        Doc.text "self"
    | .variadic none     => Doc.text "..."
    | .variadic (some p) => ppPat p ++ Doc.text ": ..."
    | .anon ty           => ppTy ty

  partial def ppTypeParams : TypeParams → Doc
    | .params [] => Doc.empty
    | .params items =>
        Doc.text "<" ++ Doc.commaList (items.map ppTypeParamItem) ++ Doc.text ">"

  partial def ppTypeParamItem : TypeParamItem → Doc
    | .ty name bounds default_ =>
        ppIdent name ++
        (bounds.map ppTraitBound |>.getD Doc.empty) ++
        (default_.map (fun t => Doc.text " = " ++ ppTy t) |>.getD Doc.empty)
    | .lifetime lt bounds =>
        ppLifetime lt ++
        (bounds.map ppTraitBound |>.getD Doc.empty)
    | .const_ name ty default_ =>
        Doc.text "const " ++ ppIdent name ++ Doc.text ": " ++ ppTy ty ++
        (default_.map (fun d => Doc.text " = " ++ ppConstParamDefault d)
          |>.getD Doc.empty)
    | .metavar n => Doc.text n

  partial def ppConstParamDefault : ConstParamDefault → Doc
    | .block b   => ppBlock b
    | .ident id  => ppIdent id
    | .literal l => ppLiteral l

  partial def ppWherePreds : List WherePred → Doc
    | [] => Doc.empty
    | preds =>
        Doc.text " where " ++
        Doc.commaList (preds.map fun
          | .ty lhs bounds   => ppTy lhs ++ ppTraitBound bounds
          | .lifetime lt bds =>
              ppLifetime lt ++ Doc.text ": " ++
              Doc.join (Doc.text " + ") (bds.map ppLifetime))

  partial def ppFieldDecl : FieldDecl → Doc
    | .mk _attrs vis name ty =>
        ppVisOpt vis ++ ppIdent name ++ Doc.text ": " ++ ppTy ty

  partial def ppTupleField : TupleField → Doc
    | .mk _attrs vis ty =>
        ppVisOpt vis ++ ppTy ty

  partial def ppStructBody : StructBody → Doc
    | .unit       => Doc.empty
    | .tuple flds =>
        Doc.text "(" ++ Doc.commaList (flds.map ppTupleField) ++ Doc.text ")"
    | .record flds =>
        Doc.braced "{" "}" (Doc.commaLine (flds.map ppFieldDecl))

  partial def ppEnumVariant : EnumVariant → Doc
    | .mk _attrs _vis name body disc =>
        ppIdent name ++ ppStructBody body ++
        (disc.map (fun e => Doc.text " = " ++ ppExpr e) |>.getD Doc.empty)

  partial def ppAttribute : Attribute → Doc
    | .mk (.normal normal) style =>
        Doc.text (if style == .inner then "#![" else "#[") ++
        ppScopedPath normal.item.path ++ ppAttrItemKind normal.item.args ++ Doc.text "]"
    | .mk (.docComment kind content) style =>
        match kind, style with
        | .line, .outer => Doc.text "///" ++ Doc.text content
        | .line, .inner => Doc.text "//!" ++ Doc.text content
        | .block, .outer => Doc.text "/**" ++ Doc.text content ++ Doc.text "*/"
        | .block, .inner => Doc.text "/*!" ++ Doc.text content ++ Doc.text "*/"

  partial def ppAttrItemKind : AttrItemKind → Doc
    | .unparsed args => ppAttrArgs args

  partial def ppAttrArgs : AttrArgs → Doc
    | .empty => Doc.empty
    | .eq expr => Doc.text " = " ++ ppExpr expr
    | .delimited args => ppDelimArgs args

  partial def ppDelimArgs : DelimArgs → Doc
    | .mk delimiter tokens =>
        let (open_, close) := match delimiter with
          | .parenthesis => ("(", ")")
          | .brace => ("{", "}")
          | .bracket => ("[", "]")
          | .invisible _ => ("", "")
        Doc.text open_ ++ ppTokenStream tokens ++ Doc.text close

  partial def ppImplTrait : ImplTrait → Doc
    | .positive ty => ppTy ty ++ Doc.text " for "
    | .negative ty => Doc.text "!" ++ ppTy ty ++ Doc.text " for "

  partial def ppAttrs (attrs : List Attribute) : Doc :=
    if attrs.isEmpty then Doc.empty
    else Doc.join Doc.nl (attrs.map ppAttribute) ++ Doc.nl

  partial def ppTraitItem : TraitItem → Doc
    | .fn_ attrs vis mods name tps params ret where_ body =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        ppFnModifiers mods ++
        Doc.text "fn " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        Doc.text "(" ++ Doc.commaList (params.map ppParam) ++ Doc.text ")" ++
        (ret.map (fun t => Doc.text " -> " ++ ppTy t) |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        (body.map (fun b => Doc.text " " ++ ppBlock b) |>.getD (Doc.text ";"))
    | .assocType attrs name tps bounds where_ default_ =>
        ppAttrs attrs ++
        Doc.text "type " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        (bounds.map ppTraitBound |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        (default_.map (fun t => Doc.text " = " ++ ppTy t) |>.getD Doc.empty) ++
        Doc.text ";"
    | .const_ attrs name ty default_ =>
        ppAttrs attrs ++
        Doc.text "const " ++ ppIdent name ++ Doc.text ": " ++ ppTy ty ++
        (default_.map (fun v => Doc.text " = " ++ ppExpr v) |>.getD Doc.empty) ++
        Doc.text ";"
    | .macro_ inv =>
        ppMacroInv inv ++ Doc.text ";"

  partial def ppImplItem : ImplItem → Doc
    | .fn_ attrs vis mods name tps params ret where_ body =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        ppFnModifiers mods ++
        Doc.text "fn " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        Doc.text "(" ++ Doc.commaList (params.map ppParam) ++ Doc.text ")" ++
        (ret.map (fun t => Doc.text " -> " ++ ppTy t) |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        Doc.text " " ++ ppBlock body
    | .assocType attrs vis name tps bounds where_ ty =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "type " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        (bounds.map ppTraitBound |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        Doc.text " = " ++ ppTy ty ++ Doc.text ";"
    | .const_ attrs vis name ty val =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "const " ++ ppIdent name ++ Doc.text ": " ++ ppTy ty ++
        Doc.text " = " ++ ppExpr val ++ Doc.text ";"
    | .macro_ inv =>
        ppMacroInv inv ++ Doc.text ";"

  partial def ppForeignItem : ForeignItem → Doc
    | .fn_ attrs vis name tps params ret where_ =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "fn " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        Doc.text "(" ++ Doc.commaList (params.map ppParam) ++ Doc.text ")" ++
        (ret.map (fun t => Doc.text " -> " ++ ppTy t) |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++ Doc.text ";"
    | .static_ attrs vis mut_ name ty =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "static " ++
        (if mut_ then Doc.text "mut " else Doc.empty) ++
        ppIdent name ++ Doc.text ": " ++ ppTy ty ++ Doc.text ";"
    | .type_ attrs vis name =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "type " ++ ppIdent name ++ Doc.text ";"
    | .macro_ inv =>
        ppMacroInv inv ++ Doc.text ";"

  partial def ppItem : Item → Doc
    | .mod attrs vis name none =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "mod " ++ ppIdent name ++ Doc.text ";"
    | .mod attrs vis name (some items) =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "mod " ++ ppIdent name ++ Doc.text " " ++
        Doc.braced "{" "}" (Doc.join Doc.nl (items.map ppItem))
    | .foreignMod attrs unsafe_ abi items =>
        ppAttrs attrs ++
        (if unsafe_ then Doc.text "unsafe " else Doc.empty) ++
        Doc.text "extern" ++
        Doc.text s!" \"{abi.getD "C"}\"" ++
        Doc.text " " ++
        Doc.braced "{" "}" (Doc.join Doc.nl (items.map ppForeignItem))
    | .struct_ attrs vis name tps where_ body =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "struct " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        ppStructBody body ++
        (match body with | .record _ => Doc.empty | _ => Doc.text ";")
    | .union_ attrs vis name tps where_ fields =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "union " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        Doc.braced "{" "}" (Doc.commaLine (fields.map ppFieldDecl))
    | .enum_ attrs vis name tps where_ variants =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "enum " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        Doc.text " " ++
        Doc.braced "{" "}" (Doc.commaLine (variants.map ppEnumVariant))
    | .typeAlias attrs vis name tps where_ ty =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "type " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        (ty.map (fun t => Doc.text " = " ++ ppTy t) |>.getD Doc.empty) ++
        Doc.text ";"
    | .traitAlias attrs vis name tps bounds =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "trait " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        Doc.text " = " ++ ppTraitBound bounds ++ Doc.text ";"
    | .fn_ attrs vis mods name tps params ret where_ body _contract _eii =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        ppFnModifiers mods ++
        Doc.text "fn " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        Doc.text "(" ++ Doc.commaList (params.map ppParam) ++ Doc.text ")" ++
        (ret.map (fun t => Doc.text " -> " ++ ppTy t) |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        (body.map (fun b => Doc.text " " ++ ppBlock b) |>.getD (Doc.text ";"))
    | .fnSig attrs vis mods name tps params ret where_ _contract =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        ppFnModifiers mods ++
        Doc.text "fn " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        Doc.text "(" ++ Doc.commaList (params.map ppParam) ++ Doc.text ")" ++
        (ret.map (fun t => Doc.text " -> " ++ ppTy t) |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++ Doc.text ";"
    | .trait_ attrs vis unsafe_ name tps bounds where_ items =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        (if unsafe_ then Doc.text "unsafe " else Doc.empty) ++
        Doc.text "trait " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        (bounds.map ppTraitBound |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        Doc.text " " ++
        Doc.braced "{" "}" (Doc.join Doc.nl (items.map ppTraitItem))
    | .impl_ attrs unsafe_ tps traitRef ty where_ items =>
        match ty with
        | .err => ppAttrs attrs ++ Doc.text "impl {}"
        | _ =>
            ppAttrs attrs ++
            (if unsafe_ then Doc.text "unsafe " else Doc.empty) ++
            Doc.text "impl" ++
            (tps.map ppTypeParams |>.getD Doc.empty) ++
            Doc.text " " ++
            (traitRef.map ppImplTrait |>.getD Doc.empty) ++
            ppTy ty ++
            (where_.map ppWherePreds |>.getD Doc.empty) ++
            Doc.text " " ++
            Doc.braced "{" "}" (Doc.join Doc.nl (items.map ppImplItem))
    | .assocType attrs name tps bounds where_ default_ =>
        ppAttrs attrs ++
        Doc.text "type " ++ ppIdent name ++
        (tps.map ppTypeParams |>.getD Doc.empty) ++
        (bounds.map ppTraitBound |>.getD Doc.empty) ++
        (where_.map ppWherePreds |>.getD Doc.empty) ++
        (default_.map (fun t => Doc.text " = " ++ ppTy t) |>.getD Doc.empty) ++
        Doc.text ";"
    | .const_ attrs vis name ty val =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "const " ++ ppIdent name ++ Doc.text ": " ++ ppTy ty ++
        (val.map (fun v => Doc.text " = " ++ ppExpr v) |>.getD Doc.empty) ++
        Doc.text ";"
    | .constBlock b =>
        Doc.text "const " ++ ppBlock b
    | .static_ attrs vis mut_ name ty val _eii =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "static " ++
        (if mut_ then Doc.text "mut " else Doc.empty) ++
        ppIdent name ++ Doc.text ": " ++ ppTy ty ++
        (val.map (fun v => Doc.text " = " ++ ppExpr v) |>.getD Doc.empty) ++
        Doc.text ";"
    | .use_ attrs vis tree =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "use " ++ ppUseTree tree ++ Doc.text ";"
    | .externCrate attrs vis name alias_ =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "extern crate " ++ ppIdent name ++
        (alias_.map (fun a => Doc.text " as " ++ ppIdent a) |>.getD Doc.empty) ++
        Doc.text ";"
    | .attribute _inner attr => ppAttribute attr
    | .macro_ inv            => ppMacroInv inv ++ Doc.text ";"
    | .macroDef name rules   =>
        Doc.text "macro_rules! " ++ ppIdent name ++ Doc.text " " ++
        Doc.braced "{" "}" (Doc.join (Doc.text ";" ++ Doc.nl) (rules.map ppMacroRule))
    | .globalAsm asm         =>
        Doc.text "global_asm!(" ++ ppInlineAsm asm ++ Doc.text ");"
    | .delegation attrs vis id target rename body =>
        ppAttrs attrs ++
        ppVisOpt vis ++
        Doc.text "reuse " ++ ppScopedPath target ++ Doc.text "::" ++ ppIdent id ++
        (rename.map (fun r => Doc.text " as " ++ ppIdent r) |>.getD Doc.empty) ++
        (body.map (fun b => Doc.text " " ++ ppBlock b) |>.getD (Doc.text ";"))
    | .delegationMac attrs target suffixes body =>
        ppAttrs attrs ++
        Doc.text "reuse " ++ ppScopedPath target ++ Doc.text "::{" ++
        Doc.commaList (suffixes.map ppIdent) ++ Doc.text "}" ++
        (body.map (fun b => Doc.text " " ++ ppBlock b) |>.getD (Doc.text ";"))
end  -- mutual

/-! ──────────────────────────────────────────────────────────────
    § 3  Top-level entry point
──────────────────────────────────────────────────────────────── -/

/-- Pretty-print an entire source file to a `String`. -/
def ppSourceFile (sf : SourceFile) : String :=
  let shebang := sf.shebang.map (· ++ "\n") |>.getD ""
  let attrStr := if sf.attrs.isEmpty then ""
    else String.intercalate "\n" (sf.attrs.map (fun a => Doc.toString (ppAttribute a))) ++ "\n"
  let items := String.intercalate "\n"
                 (sf.items.map (fun it => Doc.toString (ppItem it)))
  shebang ++ attrStr ++ items ++ if items.isEmpty then "" else "\n"
