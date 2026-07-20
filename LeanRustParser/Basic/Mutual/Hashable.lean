module

public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual

@[expose] public section

/-! Hashable instances for the current mutually-recursive rustc_ast source tree. -/

deriving instance Hashable for Path
deriving instance Hashable for PathSegment
deriving instance Hashable for Visibility
deriving instance Hashable for UseTreeKind
deriving instance Hashable for UseTree
deriving instance Hashable for GenericArgs
deriving instance Hashable for GenericArg
deriving instance Hashable for AngleBracketedArg
deriving instance Hashable for AssocItemConstraint
deriving instance Hashable for Term
deriving instance Hashable for AssocItemConstraintKind
deriving instance Hashable for QSelf
deriving instance Hashable for Ty
deriving instance Hashable for MutTy
deriving instance Hashable for FnPtrTy
deriving instance Hashable for UnsafeBinderTy
deriving instance Hashable for TyPat
deriving instance Hashable for TraitRef
deriving instance Hashable for PolyTraitRef
deriving instance Hashable for GenericBound
deriving instance Hashable for PreciseCapturingArg
deriving instance Hashable for Block
deriving instance Hashable for WhereClause
deriving instance Hashable for WherePred
deriving instance Hashable for WherePredKind
deriving instance Hashable for Generics
deriving instance Hashable for GenericParam
deriving instance Hashable for Param
deriving instance Hashable for PatField
deriving instance Hashable for Pat
deriving instance Hashable for Expr
deriving instance Hashable for ExprKind
deriving instance Hashable for YieldKind
deriving instance Hashable for ClosureBinder
deriving instance Hashable for Closure
deriving instance Hashable for Guard
deriving instance Hashable for MatchArm
deriving instance Hashable for AnonConst
deriving instance Hashable for MethodCall
deriving instance Hashable for StructRest
deriving instance Hashable for StructExpr
deriving instance Hashable for ExprField
deriving instance Hashable for LocalKind
deriving instance Hashable for Local
deriving instance Hashable for MacroCallStmt
deriving instance Hashable for Stmt
deriving instance Hashable for MacCall
deriving instance Hashable for FormatArgs
deriving instance Hashable for FormatArgument
deriving instance Hashable for FnContract
deriving instance Hashable for FnDecl
deriving instance Hashable for FnSig
deriving instance Hashable for Fn
deriving instance Hashable for ConstItemRhsKind
deriving instance Hashable for ConstItem
deriving instance Hashable for StaticItem
deriving instance Hashable for TyAlias
deriving instance Hashable for ForeignMod
deriving instance Hashable for ModKind
deriving instance Hashable for RestrictionKind
deriving instance Hashable for TraitAlias
deriving instance Hashable for Trait
deriving instance Hashable for TraitImplHeader
deriving instance Hashable for Impl
deriving instance Hashable for InlineAsmSym
deriving instance Hashable for InlineAsmOperand
deriving instance Hashable for InlineAsm
deriving instance Hashable for Delegation
deriving instance Hashable for DelegationSuffixes
deriving instance Hashable for DelegationMac
deriving instance Hashable for Item
deriving instance Hashable for AssocItemKind
deriving instance Hashable for AssocItem
deriving instance Hashable for ForeignItemKind
deriving instance Hashable for ForeignItem
deriving instance Hashable for VariantData
deriving instance Hashable for FieldDef
deriving instance Hashable for Variant
deriving instance Hashable for AttrArgs
deriving instance Hashable for AttrItem
deriving instance Hashable for AttrKind
deriving instance Hashable for Attribute

