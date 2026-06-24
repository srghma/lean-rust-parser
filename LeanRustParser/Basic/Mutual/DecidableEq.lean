module

public import LeanRustParser.Basic.Mutual

@[expose] public section

deriving instance DecidableEq for ScopedPath
deriving instance DecidableEq for TypeArgs
deriving instance DecidableEq for TypeArgItem
deriving instance DecidableEq for Ty
deriving instance DecidableEq for BareFnArg
deriving instance DecidableEq for TraitBound
deriving instance DecidableEq for TraitBoundItem
deriving instance DecidableEq for PreciseCapturingArg
deriving instance DecidableEq for Block
deriving instance DecidableEq for WherePred
deriving instance DecidableEq for TypeParams
deriving instance DecidableEq for TypeParamItem
deriving instance DecidableEq for ConstParamDefault
deriving instance DecidableEq for Param
deriving instance DecidableEq for Pat
deriving instance DecidableEq for RangePat
deriving instance DecidableEq for FieldPat
deriving instance DecidableEq for Expr
deriving instance DecidableEq for ArrayExprKind
deriving instance DecidableEq for ClosureParam
deriving instance DecidableEq for ClosureBody
deriving instance DecidableEq for Condition
deriving instance DecidableEq for LetChainItem
deriving instance DecidableEq for ElseClause
deriving instance DecidableEq for MatchArm
deriving instance DecidableEq for StructExprName
deriving instance DecidableEq for FieldInit
deriving instance DecidableEq for Stmt
deriving instance DecidableEq for MacroInvocation
deriving instance DecidableEq for EiiImpl
deriving instance DecidableEq for FnContract
deriving instance DecidableEq for InlineAsmOperand
deriving instance DecidableEq for InlineAsm
deriving instance DecidableEq for Item
deriving instance DecidableEq for ImplTrait
deriving instance DecidableEq for TraitItem
deriving instance DecidableEq for ImplItem
deriving instance DecidableEq for ForeignItem
deriving instance DecidableEq for StructBody
deriving instance DecidableEq for TupleField
deriving instance DecidableEq for FieldDecl
deriving instance DecidableEq for EnumVariant
deriving instance DecidableEq for Attribute
deriving instance DecidableEq for AttrValue
