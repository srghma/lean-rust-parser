module

public import LeanRustParser.Basic.Mutual

@[expose] public section

deriving instance Hashable for ScopedPath
deriving instance Hashable for TypeArgs
deriving instance Hashable for TypeArgItem
deriving instance Hashable for Ty
deriving instance Hashable for BareFnArg
deriving instance Hashable for TraitBound
deriving instance Hashable for TraitBoundItem
deriving instance Hashable for PreciseCapturingArg
deriving instance Hashable for Block
deriving instance Hashable for WherePred
deriving instance Hashable for TypeParams
deriving instance Hashable for TypeParamItem
deriving instance Hashable for ConstParamDefault
deriving instance Hashable for Param
deriving instance Hashable for Pat
deriving instance Hashable for RangePat
deriving instance Hashable for FieldPat
deriving instance Hashable for Expr
deriving instance Hashable for ArrayExprKind
deriving instance Hashable for ClosureParam
deriving instance Hashable for ClosureBody
deriving instance Hashable for Condition
deriving instance Hashable for LetChainItem
deriving instance Hashable for ElseClause
deriving instance Hashable for MatchArm
deriving instance Hashable for StructExprName
deriving instance Hashable for FieldInit
deriving instance Hashable for Stmt
deriving instance Hashable for MacroInvocation
deriving instance Hashable for EiiImpl
deriving instance Hashable for FnContract
deriving instance Hashable for InlineAsmOperand
deriving instance Hashable for InlineAsm
deriving instance Hashable for Item
deriving instance Hashable for ImplTrait
deriving instance Hashable for TraitItem
deriving instance Hashable for ImplItem
deriving instance Hashable for ForeignItem
deriving instance Hashable for StructBody
deriving instance Hashable for TupleField
deriving instance Hashable for FieldDecl
deriving instance Hashable for EnumVariant
deriving instance Hashable for Attribute
deriving instance Hashable for AttrValue
