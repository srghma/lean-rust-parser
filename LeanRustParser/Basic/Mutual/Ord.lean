module

public import LeanRustParser.Basic.Mutual

@[expose] public section

deriving instance Ord for ScopedPath
deriving instance Ord for TypeArgs
deriving instance Ord for TypeArgItem
deriving instance Ord for Ty
deriving instance Ord for BareFnArg
deriving instance Ord for TraitBound
deriving instance Ord for TraitBoundItem
deriving instance Ord for PreciseCapturingArg
deriving instance Ord for Block
deriving instance Ord for WherePred
deriving instance Ord for TypeParams
deriving instance Ord for TypeParamItem
deriving instance Ord for ConstParamDefault
deriving instance Ord for Param
deriving instance Ord for Pat
deriving instance Ord for RangePat
deriving instance Ord for FieldPat
deriving instance Ord for Expr
deriving instance Ord for ArrayExprKind
deriving instance Ord for ClosureParam
deriving instance Ord for ClosureBody
deriving instance Ord for Condition
deriving instance Ord for LetChainItem
deriving instance Ord for ElseClause
deriving instance Ord for MatchArm
deriving instance Ord for StructExprName
deriving instance Ord for FieldInit
deriving instance Ord for Stmt
deriving instance Ord for MacroInvocation
deriving instance Ord for EiiImpl
deriving instance Ord for FnContract
deriving instance Ord for InlineAsmOperand
deriving instance Ord for InlineAsm
deriving instance Ord for Item
deriving instance Ord for ImplTrait
deriving instance Ord for TraitItem
deriving instance Ord for ImplItem
deriving instance Ord for ForeignItem
deriving instance Ord for StructBody
deriving instance Ord for TupleField
deriving instance Ord for FieldDecl
deriving instance Ord for EnumVariant
deriving instance Ord for Attribute
deriving instance Ord for AttrKind
deriving instance Ord for NormalAttr
deriving instance Ord for AttrItem
deriving instance Ord for AttrItemKind
deriving instance Ord for AttrArgs
deriving instance Ord for DelimArgs
