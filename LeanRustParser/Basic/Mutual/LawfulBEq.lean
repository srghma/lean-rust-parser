module

public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual
public import LeanRustParser.Basic.Mutual.BEq

@[expose] public section

/-! LawfulBEq instances for the current mutually-recursive rustc_ast source tree. -/

deriving instance LawfulBEq for Path
deriving instance LawfulBEq for PathSegment
deriving instance LawfulBEq for Visibility
deriving instance LawfulBEq for UseTreeKind
deriving instance LawfulBEq for UseTree
deriving instance LawfulBEq for GenericArgs
deriving instance LawfulBEq for GenericArg
deriving instance LawfulBEq for AngleBracketedArg
deriving instance LawfulBEq for AssocItemConstraint
deriving instance LawfulBEq for Term
deriving instance LawfulBEq for AssocItemConstraintKind
deriving instance LawfulBEq for QSelf
deriving instance LawfulBEq for Ty
deriving instance LawfulBEq for MutTy
deriving instance LawfulBEq for FnPtrTy
deriving instance LawfulBEq for UnsafeBinderTy
deriving instance LawfulBEq for TyPat
deriving instance LawfulBEq for TraitRef
deriving instance LawfulBEq for PolyTraitRef
deriving instance LawfulBEq for GenericBound
deriving instance LawfulBEq for PreciseCapturingArg
deriving instance LawfulBEq for Block
deriving instance LawfulBEq for WhereClause
deriving instance LawfulBEq for WherePred
deriving instance LawfulBEq for WherePredKind
deriving instance LawfulBEq for Generics
deriving instance LawfulBEq for GenericParam
deriving instance LawfulBEq for Param
deriving instance LawfulBEq for PatField
deriving instance LawfulBEq for Pat
deriving instance LawfulBEq for Expr
deriving instance LawfulBEq for ExprKind
deriving instance LawfulBEq for YieldKind
deriving instance LawfulBEq for ClosureBinder
deriving instance LawfulBEq for Closure
deriving instance LawfulBEq for Guard
deriving instance LawfulBEq for MatchArm
deriving instance LawfulBEq for AnonConst
deriving instance LawfulBEq for MethodCall
deriving instance LawfulBEq for StructRest
deriving instance LawfulBEq for StructExpr
deriving instance LawfulBEq for ExprField
deriving instance LawfulBEq for LocalKind
deriving instance LawfulBEq for Local
deriving instance LawfulBEq for MacroCallStmt
deriving instance LawfulBEq for Stmt
deriving instance LawfulBEq for MacCall
deriving instance LawfulBEq for FormatArgs
deriving instance LawfulBEq for FormatArgument
deriving instance LawfulBEq for FnContract
deriving instance LawfulBEq for FnDecl
deriving instance LawfulBEq for FnSig
deriving instance LawfulBEq for Fn
deriving instance LawfulBEq for ConstItemRhsKind
deriving instance LawfulBEq for ConstItem
deriving instance LawfulBEq for StaticItem
deriving instance LawfulBEq for TyAlias
deriving instance LawfulBEq for ForeignMod
deriving instance LawfulBEq for ModKind
deriving instance LawfulBEq for RestrictionKind
deriving instance LawfulBEq for TraitAlias
deriving instance LawfulBEq for Trait
deriving instance LawfulBEq for TraitImplHeader
deriving instance LawfulBEq for Impl
deriving instance LawfulBEq for InlineAsmSym
deriving instance LawfulBEq for InlineAsmOperand
deriving instance LawfulBEq for InlineAsm
deriving instance LawfulBEq for Delegation
deriving instance LawfulBEq for DelegationSuffixes
deriving instance LawfulBEq for DelegationMac
deriving instance LawfulBEq for Item
deriving instance LawfulBEq for AssocItemKind
deriving instance LawfulBEq for AssocItem
deriving instance LawfulBEq for ForeignItemKind
deriving instance LawfulBEq for ForeignItem
deriving instance LawfulBEq for VariantData
deriving instance LawfulBEq for FieldDef
deriving instance LawfulBEq for Variant
deriving instance LawfulBEq for AttrArgs
deriving instance LawfulBEq for AttrItem
deriving instance LawfulBEq for AttrKind
deriving instance LawfulBEq for Attribute

