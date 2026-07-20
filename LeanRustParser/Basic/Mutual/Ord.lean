module

public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual

@[expose] public section

/-! Ord instances for the current mutually-recursive rustc_ast source tree. -/

deriving instance Ord for Path
deriving instance Ord for PathSegment
deriving instance Ord for Visibility
deriving instance Ord for UseTreeKind
deriving instance Ord for UseTree
deriving instance Ord for GenericArgs
deriving instance Ord for GenericArg
deriving instance Ord for AngleBracketedArg
deriving instance Ord for AssocItemConstraint
deriving instance Ord for Term
deriving instance Ord for AssocItemConstraintKind
deriving instance Ord for QSelf
deriving instance Ord for Ty
deriving instance Ord for MutTy
deriving instance Ord for FnPtrTy
deriving instance Ord for UnsafeBinderTy
deriving instance Ord for TyPat
deriving instance Ord for TraitRef
deriving instance Ord for PolyTraitRef
deriving instance Ord for GenericBound
deriving instance Ord for PreciseCapturingArg
deriving instance Ord for Block
deriving instance Ord for WhereClause
deriving instance Ord for WherePred
deriving instance Ord for WherePredKind
deriving instance Ord for Generics
deriving instance Ord for GenericParam
deriving instance Ord for Param
deriving instance Ord for PatField
deriving instance Ord for Pat
deriving instance Ord for Expr
deriving instance Ord for ExprKind
deriving instance Ord for YieldKind
deriving instance Ord for ClosureBinder
deriving instance Ord for Closure
deriving instance Ord for Guard
deriving instance Ord for MatchArm
deriving instance Ord for AnonConst
deriving instance Ord for MethodCall
deriving instance Ord for StructRest
deriving instance Ord for StructExpr
deriving instance Ord for ExprField
deriving instance Ord for LocalKind
deriving instance Ord for Local
deriving instance Ord for MacroCallStmt
deriving instance Ord for Stmt
deriving instance Ord for MacCall
deriving instance Ord for FormatArgs
deriving instance Ord for FormatArgument
deriving instance Ord for FnContract
deriving instance Ord for FnDecl
deriving instance Ord for FnSig
deriving instance Ord for Fn
deriving instance Ord for ConstItemRhsKind
deriving instance Ord for ConstItem
deriving instance Ord for StaticItem
deriving instance Ord for TyAlias
deriving instance Ord for ForeignMod
deriving instance Ord for ModKind
deriving instance Ord for RestrictionKind
deriving instance Ord for TraitAlias
deriving instance Ord for Trait
deriving instance Ord for TraitImplHeader
deriving instance Ord for Impl
deriving instance Ord for InlineAsmSym
deriving instance Ord for InlineAsmOperand
deriving instance Ord for InlineAsm
deriving instance Ord for Delegation
deriving instance Ord for DelegationSuffixes
deriving instance Ord for DelegationMac
deriving instance Ord for Item
deriving instance Ord for AssocItemKind
deriving instance Ord for AssocItem
deriving instance Ord for ForeignItemKind
deriving instance Ord for ForeignItem
deriving instance Ord for VariantData
deriving instance Ord for FieldDef
deriving instance Ord for Variant
deriving instance Ord for AttrArgs
deriving instance Ord for AttrItem
deriving instance Ord for AttrKind
deriving instance Ord for Attribute

