module

public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual

@[expose] public section

/-! DecidableEq instances for the current mutually-recursive rustc_ast source tree. -/

deriving instance DecidableEq for Path
deriving instance DecidableEq for PathSegment
deriving instance DecidableEq for Visibility
deriving instance DecidableEq for UseTreeKind
deriving instance DecidableEq for UseTree
deriving instance DecidableEq for GenericArgs
deriving instance DecidableEq for GenericArg
deriving instance DecidableEq for AngleBracketedArg
deriving instance DecidableEq for AssocItemConstraint
deriving instance DecidableEq for Term
deriving instance DecidableEq for AssocItemConstraintKind
deriving instance DecidableEq for QSelf
deriving instance DecidableEq for Ty
deriving instance DecidableEq for MutTy
deriving instance DecidableEq for FnPtrTy
deriving instance DecidableEq for UnsafeBinderTy
deriving instance DecidableEq for TyPat
deriving instance DecidableEq for TraitRef
deriving instance DecidableEq for PolyTraitRef
deriving instance DecidableEq for GenericBound
deriving instance DecidableEq for PreciseCapturingArg
deriving instance DecidableEq for Block
deriving instance DecidableEq for WhereClause
deriving instance DecidableEq for WherePred
deriving instance DecidableEq for WherePredKind
deriving instance DecidableEq for Generics
deriving instance DecidableEq for GenericParam
deriving instance DecidableEq for Param
deriving instance DecidableEq for PatField
deriving instance DecidableEq for Pat
deriving instance DecidableEq for Expr
deriving instance DecidableEq for ExprKind
deriving instance DecidableEq for YieldKind
deriving instance DecidableEq for ClosureBinder
deriving instance DecidableEq for Closure
deriving instance DecidableEq for Guard
deriving instance DecidableEq for MatchArm
deriving instance DecidableEq for AnonConst
deriving instance DecidableEq for MethodCall
deriving instance DecidableEq for StructRest
deriving instance DecidableEq for StructExpr
deriving instance DecidableEq for ExprField
deriving instance DecidableEq for LocalKind
deriving instance DecidableEq for Local
deriving instance DecidableEq for MacroCallStmt
deriving instance DecidableEq for Stmt
deriving instance DecidableEq for MacCall
deriving instance DecidableEq for FormatArgs
deriving instance DecidableEq for FormatArgument
deriving instance DecidableEq for FnContract
deriving instance DecidableEq for FnDecl
deriving instance DecidableEq for FnSig
deriving instance DecidableEq for Fn
deriving instance DecidableEq for ConstItemRhsKind
deriving instance DecidableEq for ConstItem
deriving instance DecidableEq for StaticItem
deriving instance DecidableEq for TyAlias
deriving instance DecidableEq for ForeignMod
deriving instance DecidableEq for ModKind
deriving instance DecidableEq for RestrictionKind
deriving instance DecidableEq for TraitAlias
deriving instance DecidableEq for Trait
deriving instance DecidableEq for TraitImplHeader
deriving instance DecidableEq for Impl
deriving instance DecidableEq for InlineAsmSym
deriving instance DecidableEq for InlineAsmOperand
deriving instance DecidableEq for InlineAsm
deriving instance DecidableEq for Delegation
deriving instance DecidableEq for DelegationSuffixes
deriving instance DecidableEq for DelegationMac
deriving instance DecidableEq for Item
deriving instance DecidableEq for AssocItemKind
deriving instance DecidableEq for AssocItem
deriving instance DecidableEq for ForeignItemKind
deriving instance DecidableEq for ForeignItem
deriving instance DecidableEq for VariantData
deriving instance DecidableEq for FieldDef
deriving instance DecidableEq for Variant
deriving instance DecidableEq for AttrArgs
deriving instance DecidableEq for AttrItem
deriving instance DecidableEq for AttrKind
deriving instance DecidableEq for Attribute

