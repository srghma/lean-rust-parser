module

public import LeanRustParser.Basic.Mutual

@[expose] public section

deriving instance Repr for ScopedPath
deriving instance Repr for TypeArgs
deriving instance Repr for TypeArgItem
deriving instance Repr for Ty
deriving instance Repr for BareFnArg
deriving instance Repr for TraitBound
deriving instance Repr for TraitBoundItem
deriving instance Repr for PreciseCapturingArg
deriving instance Repr for Block
deriving instance Repr for WherePred
deriving instance Repr for TypeParams
deriving instance Repr for TypeParamItem
deriving instance Repr for ConstParamDefault
deriving instance Repr for Param
deriving instance Repr for Pat
deriving instance Repr for RangePat
deriving instance Repr for FieldPat
deriving instance Repr for Expr
deriving instance Repr for ArrayExprKind
deriving instance Repr for ClosureParam
deriving instance Repr for ClosureBody
deriving instance Repr for Condition
deriving instance Repr for LetChainItem
deriving instance Repr for ElseClause
deriving instance Repr for MatchArm
deriving instance Repr for StructExprName
deriving instance Repr for FieldInit
deriving instance Repr for Stmt
deriving instance Repr for MacroInvocation
deriving instance Repr for EiiImpl
deriving instance Repr for FnContract
deriving instance Repr for InlineAsmOperand
deriving instance Repr for InlineAsm
deriving instance Repr for Item
deriving instance Repr for ImplTrait
deriving instance Repr for TraitItem
deriving instance Repr for ImplItem
deriving instance Repr for ForeignItem
deriving instance Repr for StructBody
deriving instance Repr for TupleField
deriving instance Repr for FieldDecl
deriving instance Repr for EnumVariant
deriving instance Repr for Attribute
deriving instance Repr for AttrKind
deriving instance Repr for NormalAttr
deriving instance Repr for AttrItem
deriving instance Repr for AttrItemKind
deriving instance Repr for AttrArgs
deriving instance Repr for DelimArgs
