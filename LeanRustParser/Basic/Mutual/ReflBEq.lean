module

public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual
public import LeanRustParser.Basic.Mutual.BEq

@[expose] public section

/-! ReflBEq instances for the current mutually-recursive rustc_ast source tree. -/

deriving instance ReflBEq for Path
deriving instance ReflBEq for PathSegment
deriving instance ReflBEq for Visibility
deriving instance ReflBEq for UseTreeKind
deriving instance ReflBEq for UseTree
deriving instance ReflBEq for GenericArgs
deriving instance ReflBEq for GenericArg
deriving instance ReflBEq for AngleBracketedArg
deriving instance ReflBEq for AssocItemConstraint
deriving instance ReflBEq for Term
deriving instance ReflBEq for AssocItemConstraintKind
deriving instance ReflBEq for QSelf
deriving instance ReflBEq for Ty
deriving instance ReflBEq for MutTy
deriving instance ReflBEq for FnPtrTy
deriving instance ReflBEq for UnsafeBinderTy
deriving instance ReflBEq for TyPat
deriving instance ReflBEq for TraitRef
deriving instance ReflBEq for PolyTraitRef
deriving instance ReflBEq for GenericBound
deriving instance ReflBEq for PreciseCapturingArg
deriving instance ReflBEq for Block
deriving instance ReflBEq for WhereClause
deriving instance ReflBEq for WherePred
deriving instance ReflBEq for WherePredKind
deriving instance ReflBEq for Generics
deriving instance ReflBEq for GenericParam
deriving instance ReflBEq for Param
deriving instance ReflBEq for PatField
deriving instance ReflBEq for Pat
deriving instance ReflBEq for Expr
deriving instance ReflBEq for ExprKind
deriving instance ReflBEq for YieldKind
deriving instance ReflBEq for ClosureBinder
deriving instance ReflBEq for Closure
deriving instance ReflBEq for Guard
deriving instance ReflBEq for MatchArm
deriving instance ReflBEq for AnonConst
deriving instance ReflBEq for MethodCall
deriving instance ReflBEq for StructRest
deriving instance ReflBEq for StructExpr
deriving instance ReflBEq for ExprField
deriving instance ReflBEq for LocalKind
deriving instance ReflBEq for Local
deriving instance ReflBEq for MacroCallStmt
deriving instance ReflBEq for Stmt
deriving instance ReflBEq for MacCall
deriving instance ReflBEq for FormatArgs
deriving instance ReflBEq for FormatArgument
deriving instance ReflBEq for FnContract
deriving instance ReflBEq for FnDecl
deriving instance ReflBEq for FnSig
deriving instance ReflBEq for Fn
deriving instance ReflBEq for ConstItemRhsKind
deriving instance ReflBEq for ConstItem
deriving instance ReflBEq for StaticItem
deriving instance ReflBEq for TyAlias
deriving instance ReflBEq for ForeignMod
deriving instance ReflBEq for ModKind
deriving instance ReflBEq for RestrictionKind
deriving instance ReflBEq for TraitAlias
deriving instance ReflBEq for Trait
deriving instance ReflBEq for TraitImplHeader
deriving instance ReflBEq for Impl
deriving instance ReflBEq for InlineAsmSym
deriving instance ReflBEq for InlineAsmOperand
deriving instance ReflBEq for InlineAsm
deriving instance ReflBEq for Delegation
deriving instance ReflBEq for DelegationSuffixes
deriving instance ReflBEq for DelegationMac
deriving instance ReflBEq for Item
deriving instance ReflBEq for AssocItemKind
deriving instance ReflBEq for AssocItem
deriving instance ReflBEq for ForeignItemKind
deriving instance ReflBEq for ForeignItem
deriving instance ReflBEq for VariantData
deriving instance ReflBEq for FieldDef
deriving instance ReflBEq for Variant
deriving instance ReflBEq for AttrArgs
deriving instance ReflBEq for AttrItem
deriving instance ReflBEq for AttrKind
deriving instance ReflBEq for Attribute

