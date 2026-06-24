module

public import LeanRustParser.Basic.Mutual

@[expose] public section

deriving instance BEq for ScopedPath
deriving instance BEq for TypeArgs
deriving instance BEq for TypeArgItem
deriving instance BEq for Ty
deriving instance BEq for BareFnArg
deriving instance BEq for TraitBound
deriving instance BEq for TraitBoundItem
deriving instance BEq for PreciseCapturingArg
deriving instance BEq for Block
deriving instance BEq for WherePred
deriving instance BEq for TypeParams
deriving instance BEq for TypeParamItem
deriving instance BEq for ConstParamDefault
deriving instance BEq for Param
deriving instance BEq for Pat
deriving instance BEq for RangePat
deriving instance BEq for FieldPat
deriving instance BEq for Expr
deriving instance BEq for ArrayExprKind
deriving instance BEq for ClosureParam
deriving instance BEq for ClosureBody
deriving instance BEq for Condition
deriving instance BEq for LetChainItem
deriving instance BEq for ElseClause
deriving instance BEq for MatchArm
deriving instance BEq for StructExprName
deriving instance BEq for FieldInit
deriving instance BEq for Stmt
deriving instance BEq for MacroInvocation
deriving instance BEq for EiiImpl
deriving instance BEq for FnContract
deriving instance BEq for InlineAsmOperand
deriving instance BEq for InlineAsm
deriving instance BEq for Item
deriving instance BEq for ImplTrait
deriving instance BEq for TraitItem
deriving instance BEq for ImplItem
deriving instance BEq for ForeignItem
deriving instance BEq for StructBody
deriving instance BEq for TupleField
deriving instance BEq for FieldDecl
deriving instance BEq for EnumVariant
deriving instance BEq for Attribute
deriving instance BEq for AttrValue
