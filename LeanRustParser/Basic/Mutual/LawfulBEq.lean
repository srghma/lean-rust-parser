module

public import LeanRustParser.Basic.Mutual

@[expose] public section

deriving instance LawfulBEq for ScopedPath
deriving instance LawfulBEq for TypeArgs
deriving instance LawfulBEq for TypeArgItem
deriving instance LawfulBEq for Ty
deriving instance LawfulBEq for BareFnArg
deriving instance LawfulBEq for TraitBound
deriving instance LawfulBEq for TraitBoundItem
deriving instance LawfulBEq for PreciseCapturingArg
deriving instance LawfulBEq for Block
deriving instance LawfulBEq for WherePred
deriving instance LawfulBEq for TypeParams
deriving instance LawfulBEq for TypeParamItem
deriving instance LawfulBEq for ConstParamDefault
deriving instance LawfulBEq for Param
deriving instance LawfulBEq for Pat
deriving instance LawfulBEq for RangePat
deriving instance LawfulBEq for FieldPat
deriving instance LawfulBEq for Expr
deriving instance LawfulBEq for ArrayExprKind
deriving instance LawfulBEq for ClosureParam
deriving instance LawfulBEq for ClosureBody
deriving instance LawfulBEq for Condition
deriving instance LawfulBEq for LetChainItem
deriving instance LawfulBEq for ElseClause
deriving instance LawfulBEq for MatchArm
deriving instance LawfulBEq for StructExprName
deriving instance LawfulBEq for FieldInit
deriving instance LawfulBEq for Stmt
deriving instance LawfulBEq for MacroInvocation
deriving instance LawfulBEq for EiiImpl
deriving instance LawfulBEq for FnContract
deriving instance LawfulBEq for InlineAsmOperand
deriving instance LawfulBEq for InlineAsm
deriving instance LawfulBEq for Item
deriving instance LawfulBEq for ImplTrait
deriving instance LawfulBEq for TraitItem
deriving instance LawfulBEq for ImplItem
deriving instance LawfulBEq for ForeignItem
deriving instance LawfulBEq for StructBody
deriving instance LawfulBEq for TupleField
deriving instance LawfulBEq for FieldDecl
deriving instance LawfulBEq for EnumVariant
deriving instance LawfulBEq for Attribute
deriving instance LawfulBEq for AttrKind
deriving instance LawfulBEq for NormalAttr
deriving instance LawfulBEq for AttrItem
deriving instance LawfulBEq for AttrItemKind
deriving instance LawfulBEq for AttrArgs
deriving instance LawfulBEq for DelimArgs
