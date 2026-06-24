module

public import LeanRustParser.Basic.Mutual

@[expose] public section

deriving instance Inhabited for ScopedPath
deriving instance Inhabited for TypeArgs
deriving instance Inhabited for TypeArgItem
deriving instance Inhabited for Ty
deriving instance Inhabited for BareFnArg
deriving instance Inhabited for TraitBound
deriving instance Inhabited for TraitBoundItem
deriving instance Inhabited for PreciseCapturingArg
deriving instance Inhabited for Block
deriving instance Inhabited for WherePred
deriving instance Inhabited for TypeParams
deriving instance Inhabited for TypeParamItem
deriving instance Inhabited for ConstParamDefault
deriving instance Inhabited for Param
deriving instance Inhabited for Pat
deriving instance Inhabited for RangePat
deriving instance Inhabited for FieldPat
deriving instance Inhabited for Expr
deriving instance Inhabited for ArrayExprKind
deriving instance Inhabited for ClosureParam
deriving instance Inhabited for ClosureBody
deriving instance Inhabited for Condition
deriving instance Inhabited for LetChainItem
deriving instance Inhabited for ElseClause
deriving instance Inhabited for MatchArm
deriving instance Inhabited for StructExprName
deriving instance Inhabited for FieldInit
deriving instance Inhabited for Stmt
deriving instance Inhabited for MacroInvocation
deriving instance Inhabited for EiiImpl
deriving instance Inhabited for FnContract
deriving instance Inhabited for InlineAsmOperand
deriving instance Inhabited for InlineAsm
deriving instance Inhabited for Item
deriving instance Inhabited for ImplTrait
deriving instance Inhabited for TraitItem
deriving instance Inhabited for ImplItem
deriving instance Inhabited for ForeignItem
deriving instance Inhabited for StructBody
deriving instance Inhabited for TupleField
deriving instance Inhabited for FieldDecl
deriving instance Inhabited for EnumVariant
deriving instance Inhabited for Attribute
deriving instance Inhabited for AttrValue
