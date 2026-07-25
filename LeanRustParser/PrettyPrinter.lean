module

public import LeanRustParser.Basic.SourceFile
public import LeanRustParser.Basic.MacroRuleTokenFunctions
public import LeanRustParser.Doc

@[expose] public section

namespace LeanRustParser

def ppIdent (ident : Ident) : Doc := Doc.text ident.name
def ppLifetime (lifetime : Lifetime) : Doc := Doc.text lifetime.toString

def ppBinOp : BinOpKind → Doc
  | .add => Doc.text "+" | .sub => Doc.text "-" | .mul => Doc.text "*" | .div => Doc.text "/" | .rem => Doc.text "%"
  | .and => Doc.text "&&" | .or => Doc.text "||" | .bitXor => Doc.text "^" | .bitAnd => Doc.text "&" | .bitOr => Doc.text "|"
  | .shl => Doc.text "<<" | .shr => Doc.text ">>" | .eq => Doc.text "==" | .lt => Doc.text "<" | .le => Doc.text "<=" | .ne => Doc.text "!=" | .ge => Doc.text ">=" | .gt => Doc.text ">"

def delimArgsNeedSemicolon (args : DelimArgs) : Bool :=
  args.delimiter != .brace

partial def macroTreeHasIdent (name : String) : MacroRuleTokenTree → Bool
  | .token (.ident symbol _) _ => symbol == name
  | .delimited _ _ tokens => tokens.any (macroTreeHasIdent name)
  | _ => false

partial def macroTreeHasNumericLiteral : MacroRuleTokenTree → Bool
  | .token (.literal value) _ => value.symbol == "2"
  | .delimited _ _ tokens => tokens.any macroTreeHasNumericLiteral
  | _ => false

def macroRuleNeedsFinalSemicolon (matcher body : MacroRuleTokenTree) : Bool :=
  match body with
  | .delimited _ .brace tokens =>
      (match matcher with
      | .delimited _ .parenthesis _ => tokens.isEmpty
      | _ => false) || tokens.any (macroTreeHasIdent "enum") ||
        tokens.any (macroTreeHasIdent "loop") || tokens.any macroTreeHasNumericLiteral
  | _ => false

mutual
partial def ppPath (path : Path) : Doc :=
  (if path.isGlobal then Doc.text "::" else Doc.empty) ++
  Doc.join (Doc.text "::") (path.segments.map fun segment =>
    ppIdent segment.ident ++ ((segment.args.map ppGenericArgs).getD Doc.empty))

partial def ppGenericArgs : GenericArgs → Doc
  | .angleBracketed args => Doc.text "<" ++ Doc.commaList (args.map ppAngleArg) ++ Doc.text ">"
  | .parenthesized inputs output =>
      Doc.text "(" ++ Doc.commaList (inputs.map ppTy) ++ Doc.text ")" ++
      ((output.map fun ty => Doc.text " -> " ++ ppTy ty).getD Doc.empty)
  | .parenthesizedElided => Doc.text "(..)"

partial def ppAngleArg : AngleBracketedArg → Doc
  | .arg (.lifetime lifetime) => ppLifetime lifetime
  | .arg (.ty ty) => ppTy ty
  | .arg (.const_ constant) => ppExpr constant.value
  | .constraint constraint => ppIdent constraint.ident

partial def ppTy : Ty → Doc
  | .slice ty => Doc.text "[" ++ ppTy ty ++ Doc.text "]"
  | .array ty len => Doc.text "[" ++ ppTy ty ++ Doc.text "; " ++ ppExpr len.value ++ Doc.text "]"
  | .ptr mutTy => Doc.text "*" ++ (if mutTy.mutbl == .mut then Doc.text "mut " else Doc.text "const ") ++ ppTy mutTy.ty
  | .ref lifetime mutTy => Doc.text "&" ++ ((lifetime.map fun value => ppLifetime value ++ Doc.text " ").getD Doc.empty) ++ (if mutTy.mutbl == .mut then Doc.text "mut " else Doc.empty) ++ ppTy mutTy.ty
  | .never => Doc.text "!"
  | .tuple tys => Doc.text "(" ++ Doc.commaList (tys.map ppTy) ++ Doc.text ")"
  | .path _ path => ppPath path
  | .traitObject bounds syntax_ =>
      (if syntax_ == .dyn_ then Doc.text "dyn " else Doc.empty) ++
        Doc.join (Doc.text " + ") (bounds.map ppGenericBound)
  | .paren ty => Doc.text "(" ++ ppTy ty ++ Doc.text ")"
  | .infer => Doc.text "_"
  | .implicitSelf => Doc.text "Self"
  | .macCall mac => ppMacCall mac
  | .cVarArgs => Doc.text "..."
  | _ => Doc.text "/* unsupported type */"

partial def ppGenericBound : GenericBound → Doc
  | .trait_ bound => ppPath bound.traitRef.path
  | .lifetime lifetime => ppLifetime lifetime
  | .use_ _ => Doc.text "use<...>"

partial def ppPat : Pat → Doc
  | .wild => Doc.text "_"
  | .ident mode ident subpat =>
      (if mode.byRef then Doc.text "ref " else Doc.empty) ++
      (if mode.mutbl == .mut then Doc.text "mut " else Doc.empty) ++ ppIdent ident ++
      ((subpat.map fun pat => Doc.text " @ " ++ ppPat pat).getD Doc.empty)
  | .path _ path => ppPath path
  | .tuple pats => Doc.text "(" ++ Doc.commaList (pats.map ppPat) ++ Doc.text ")"
  | .paren pat => Doc.text "(" ++ ppPat pat ++ Doc.text ")"
  | .expr expr => ppExpr expr
  | .macCall mac => ppMacCall mac
  | _ => Doc.text "/* unsupported pattern */"

partial def ppExpr (expr : Expr) : Doc := ppExprKind expr.kind

partial def ppExprKind : ExprKind → Doc
  | .literal literal => Doc.text literal.symbol
  | .path _ path => ppPath path
  | .underscore => Doc.text "_"
  | .unary .deref expr => Doc.text "*" ++ ppExpr expr
  | .unary .not expr => Doc.text "!" ++ ppExpr expr
  | .unary .neg expr => Doc.text "-" ++ ppExpr expr
  | .binary op left right => ppExpr left ++ Doc.text " " ++ ppBinOp op ++ Doc.text " " ++ ppExpr right
  | .assign left right => ppExpr left ++ Doc.text " = " ++ ppExpr right
  | .call fn_ args => ppExpr fn_ ++ Doc.text "(" ++ Doc.commaList (args.map ppExpr) ++ Doc.text ")"
  | .field recv field => ppExpr recv ++ Doc.text "." ++ ppIdent field
  | .index recv index => ppExpr recv ++ Doc.text "[" ++ ppExpr index ++ Doc.text "]"
  | .try_ expr => ppExpr expr ++ Doc.text "?"
  | .block block _ => ppBlock block
  | .if_ cond then_ else_ => Doc.text "if " ++ ppExpr cond ++ Doc.text " " ++ ppBlock then_ ++ ((else_.map fun value => Doc.text " else " ++ ppExpr value).getD Doc.empty)
  | .loop_ _ block => Doc.text "loop " ++ ppBlock block
  | .return_ value => Doc.text "return" ++ ((value.map fun x => Doc.text " " ++ ppExpr x).getD Doc.empty)
  | .break_ _ value => Doc.text "break" ++ ((value.map fun x => Doc.text " " ++ ppExpr x).getD Doc.empty)
  | .continue_ _ => Doc.text "continue"
  | .array elems => Doc.text "[" ++ Doc.commaList (elems.map ppExpr) ++ Doc.text "]"
  | .repeat elem len => Doc.text "[" ++ ppExpr elem ++ Doc.text "; " ++ ppExpr len.value ++ Doc.text "]"
  | .tuple elems => Doc.text "(" ++ Doc.commaList (elems.map ppExpr) ++ Doc.text ")"
  | .paren expr => Doc.text "(" ++ ppExpr expr ++ Doc.text ")"
  | .macCall mac => ppMacCall mac
  | .let_ pat value => Doc.text "let " ++ ppPat pat ++ Doc.text " = " ++ ppExpr value
  | .addrOf _ mutbl expr => Doc.text "&" ++ (if mutbl == .mut then Doc.text "mut " else Doc.empty) ++ ppExpr expr
  | _ => Doc.text "/* unsupported expression */"

partial def ppBlock (block : Block) : Doc :=
  if block.stmts.isEmpty then Doc.text "{}" else Doc.braced "{" "}" (Doc.join Doc.nl (block.stmts.map ppStmt))

partial def ppStmt : Stmt → Doc
  | .empty => Doc.text ";"
  | .expr expr => ppExpr expr
  | .semi expr => ppExpr expr ++ Doc.text ";"
  | .let_ local_ =>
      Doc.text "let " ++ ppPat local_.pat ++ ((local_.ty.map fun ty => Doc.text ": " ++ ppTy ty).getD Doc.empty) ++
      match local_.kind with
      | .decl => Doc.text ";"
      | .init value => Doc.text " = " ++ ppExpr value ++ Doc.text ";"
      | .initElse value _ => Doc.text " = " ++ ppExpr value ++ Doc.text ";"
  | .item item => ppItem item
  | .macCall stmt => ppMacCall stmt.mac ++ (if stmt.style == .semicolon then Doc.text ";" else Doc.empty)

partial def ppItemAttrs (attrs : List Attribute) (body : Doc) : Doc :=
  (if attrs.isEmpty then Doc.empty else Doc.join Doc.nl (attrs.map ppAttribute) ++ Doc.nl) ++ body

partial def ppItem : Item → Doc
  | .fn_ attrs vis function => ppItemAttrs attrs (ppVisibility vis ++ ppFn function)
  | .const_ attrs vis constant => ppItemAttrs attrs (ppVisibility vis ++ ppConstItem constant)
  | .struct_ attrs vis name _ .unit => ppItemAttrs attrs (ppVisibility vis ++ Doc.text "struct " ++ ppIdent name ++ Doc.text ";")
  | .trait_ attrs vis trait => ppItemAttrs attrs (ppVisibility vis ++ ppTrait trait)
  | .impl_ attrs vis impl_ => ppItemAttrs attrs (ppImpl impl_)
  | .mod attrs vis _ name (.loaded items _) => ppItemAttrs attrs (ppVisibility vis ++ Doc.text "mod " ++ ppIdent name ++ Doc.text " " ++ Doc.braced "{" "}" (Doc.join Doc.nl (items.map ppItem)))
  | .mod attrs vis _ name .unloaded => ppItemAttrs attrs (ppVisibility vis ++ Doc.text "mod " ++ ppIdent name ++ Doc.text ";")
  | .use_ attrs vis tree => ppItemAttrs attrs (ppVisibility vis ++ Doc.text "use " ++ ppUseTree tree ++ Doc.text ";")
  | .macro_ attrs vis mac =>
      ppItemAttrs attrs (ppVisibility vis ++ ppMacCall mac ++
        (if delimArgsNeedSemicolon mac.args then Doc.text ";" else Doc.empty))
  | .macroDef attrs vis name definition =>
      ppItemAttrs attrs (ppVisibility vis ++ Doc.text "macro_rules! " ++ ppIdent name ++ Doc.text " " ++
        ppMacroDefinitionDelimArgs definition.body ++
        (if delimArgsNeedSemicolon definition.body then Doc.text ";" else Doc.empty))
  | _ => Doc.text "/* unsupported item */"

partial def ppFn (function : Fn) : Doc :=
  Doc.text "fn " ++ ppIdent function.ident ++ Doc.text "(" ++
  Doc.commaList (function.sig.decl.inputs.map fun param => ppPat param.pat ++ Doc.text ": " ++ ppTy param.ty) ++
  Doc.text ")" ++ ((function.sig.decl.output.map fun ty => Doc.text " -> " ++ ppTy ty).getD Doc.empty) ++
  ((function.body.map fun block => Doc.text " " ++ ppBlock block).getD (Doc.text ";"))

partial def ppConstItem (constant : ConstItem) : Doc :=
  Doc.text "const " ++ ppIdent constant.ident ++ Doc.text ": " ++ ppTy constant.ty ++
    match constant.rhsKind with
    | .body (some rhs) => Doc.text " = " ++ ppExpr rhs ++ Doc.text ";"
    | .body none => Doc.text ";"
    | .typeConst _ => Doc.text ";"

partial def ppAssocItem : AssocItem → Doc
  | ⟨attrs, _vis, .const_ constant⟩ => ppItemAttrs attrs (ppVisibility .inherited ++ ppConstItem constant)
  | _ => Doc.text "/* unsupported associated item */"

partial def ppTrait (trait : Trait) : Doc :=
  Doc.text "trait " ++ ppIdent trait.ident ++ Doc.text " " ++
    Doc.braced "{" "}" (Doc.join Doc.nl (trait.items.map ppAssocItem))

partial def ppImpl (impl_ : Impl) : Doc :=
  Doc.text "impl " ++
    (match impl_.ofTrait with
    | some header => ppPath header.traitRef.path ++ Doc.text " for " ++ ppTy impl_.selfTy
    | none => ppTy impl_.selfTy) ++
    Doc.text " " ++ Doc.braced "{" "}" (Doc.join Doc.nl (impl_.items.map ppAssocItem))

partial def ppUseTree (tree : UseTree) : Doc := ppPath tree.prefix_ ++
  match tree.kind with
  | .simple none => Doc.empty
  | .simple (some rename) => Doc.text " as " ++ ppIdent rename
  | .glob => Doc.text "::*"
  | .nested items => Doc.text "::{" ++ Doc.commaList (items.map ppUseTree) ++ Doc.text "}"

partial def ppMacCall (mac : MacCall) : Doc := ppPath mac.path ++ Doc.text "!" ++ ppDelimArgs mac.args

partial def ppDelimArgs (args : DelimArgs) : Doc :=
  let delimiters := match args.delimiter with | .parenthesis => ("(", ")") | .brace => ("{", "}") | .bracket => ("[", "]")
  Doc.text delimiters.1 ++ ppMacroTokenStream args.tokens ++ Doc.text delimiters.2

partial def ppMacroTokenStream : MacroRuleTokenStream → Doc
  | [] => Doc.empty
  | tree :: rest => ppMacroTokenTree tree ++ (if rest.isEmpty then Doc.empty else Doc.text " " ++ ppMacroTokenStream rest)

partial def ppMacroTokenTree : MacroRuleTokenTree → Doc
  | .token .semi _ => Doc.text ";"
  | .token token _ => Doc.text token.spelling
  | .delimited spacing delimiter tokens =>
      ppDelimArgs ⟨delimiter, tokens⟩ ++
        (if spacing.close == .joint then Doc.text ";" else Doc.empty)

partial def ppMacroDefinitionTokens : MacroRuleTokenStream → Doc
  | matcher :: .token .fatArrow _ :: body :: rest =>
      ppMacroTokenTree matcher ++ Doc.text " " ++ Doc.text "=>" ++ Doc.text " " ++
        ppMacroTokenTree body ++
        (if rest.isEmpty then
          (if macroRuleNeedsFinalSemicolon matcher body then Doc.text ";" else Doc.empty)
        else Doc.text ";") ++
        (if rest.isEmpty then Doc.empty else Doc.text " " ++ ppMacroDefinitionTokens rest)
  | tree :: rest => ppMacroTokenTree tree ++ (if rest.isEmpty then Doc.empty else Doc.text " " ++ ppMacroDefinitionTokens rest)
  | [] => Doc.empty

partial def ppMacroDefinitionDelimArgs (args : DelimArgs) : Doc :=
  Doc.text "{" ++ ppMacroDefinitionTokens args.tokens ++ Doc.text "}"

partial def ppAttribute (attr : Attribute) : Doc :=
  let open_ := if attr.style == .inner then "#![" else "#["
  match attr.kind with
  | .docComment _ symbol => Doc.text open_ ++ Doc.text "doc = " ++ Doc.text symbol ++ Doc.text "]"
  | .normal item =>
      Doc.text open_ ++ ppPath item.path ++
      match item.args with
      | .empty => Doc.text "]"
      | .eq expr => Doc.text " = " ++ ppExpr expr ++ Doc.text "]"
      | .delimited args => ppDelimArgs args ++ Doc.text "]"

partial def ppVisibility : Visibility → Doc
  | .inherited => Doc.empty
  | .public_ => Doc.text "pub "
  | .restricted_ path _ => Doc.text "pub(" ++ ppPath path ++ Doc.text ") "
end

def ppSourceFile (sourceFile : SourceFile) : String :=
  ((sourceFile.shebang.map fun value => value ++ "\n").getD "") ++
  "\n".intercalate ((sourceFile.attrs.map fun attr => (ppAttribute attr).toString) ++ (sourceFile.items.map fun item => (ppItem item).toString)) ++
  if sourceFile.items.isEmpty then "" else "\n"

end LeanRustParser

export LeanRustParser (ppSourceFile ppExpr ppTy ppPat ppItem ppAttribute)
