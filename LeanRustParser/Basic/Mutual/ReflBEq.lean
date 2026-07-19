module

public import LeanRustParser.Basic.Mutual

@[expose] public section

deriving instance ReflBEq for ScopedPath
deriving instance ReflBEq for TypeArgs
deriving instance ReflBEq for TypeArgItem
deriving instance ReflBEq for Ty
deriving instance ReflBEq for BareFnArg
deriving instance ReflBEq for TraitBound
deriving instance ReflBEq for TraitBoundItem
deriving instance ReflBEq for PreciseCapturingArg
deriving instance ReflBEq for Block
deriving instance ReflBEq for WherePred
deriving instance ReflBEq for TypeParams
deriving instance ReflBEq for TypeParamItem
deriving instance ReflBEq for ConstParamDefault
deriving instance ReflBEq for Param
deriving instance ReflBEq for Pat
deriving instance ReflBEq for RangePat
deriving instance ReflBEq for FieldPat
deriving instance ReflBEq for Expr
deriving instance ReflBEq for ArrayExprKind
deriving instance ReflBEq for ClosureParam
deriving instance ReflBEq for ClosureBody
deriving instance ReflBEq for Condition
deriving instance ReflBEq for LetChainItem
deriving instance ReflBEq for ElseClause
deriving instance ReflBEq for MatchArm
deriving instance ReflBEq for StructExprName
deriving instance ReflBEq for FieldInit
deriving instance ReflBEq for Stmt
deriving instance ReflBEq for MacroInvocation
deriving instance ReflBEq for EiiImpl
deriving instance ReflBEq for FnContract
deriving instance ReflBEq for InlineAsmOperand
deriving instance ReflBEq for InlineAsm
deriving instance ReflBEq for Item
deriving instance ReflBEq for ImplTrait
deriving instance ReflBEq for TraitItem
deriving instance ReflBEq for ImplItem
deriving instance ReflBEq for ForeignItem
deriving instance ReflBEq for StructBody
deriving instance ReflBEq for TupleField
deriving instance ReflBEq for FieldDecl
deriving instance ReflBEq for EnumVariant
deriving instance ReflBEq for Attribute
deriving instance ReflBEq for AttrKind
deriving instance ReflBEq for NormalAttr
deriving instance ReflBEq for AttrItem
deriving instance ReflBEq for AttrItemKind
deriving instance ReflBEq for AttrArgs
deriving instance ReflBEq for DelimArgs
