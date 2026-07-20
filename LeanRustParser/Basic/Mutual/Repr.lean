module

public import LeanRustParser.Basic.Mutual

@[expose] public section

/-! `Repr` instances for the current mutually-recursive `rustc_ast` source
tree.  Removed compatibility AST names intentionally have no instances. -/

deriving instance Repr for Path
deriving instance Repr for PathSegment
deriving instance Repr for Visibility
deriving instance Repr for UseTreeKind
deriving instance Repr for UseTree
deriving instance Repr for GenericArgs
deriving instance Repr for GenericArg
deriving instance Repr for AngleBracketedArg
deriving instance Repr for AssocItemConstraint
deriving instance Repr for Term
deriving instance Repr for AssocItemConstraintKind
deriving instance Repr for QSelf
deriving instance Repr for Ty
deriving instance Repr for MutTy
deriving instance Repr for FnPtrTy
deriving instance Repr for UnsafeBinderTy
deriving instance Repr for TyPat
deriving instance Repr for TraitRef
deriving instance Repr for PolyTraitRef
deriving instance Repr for GenericBound
deriving instance Repr for PreciseCapturingArg
deriving instance Repr for Block
deriving instance Repr for WhereClause
deriving instance Repr for WherePred
deriving instance Repr for WherePredKind
deriving instance Repr for Generics
deriving instance Repr for GenericParam
deriving instance Repr for Param
deriving instance Repr for PatField
deriving instance Repr for Pat
deriving instance Repr for Expr
deriving instance Repr for ExprKind
deriving instance Repr for YieldKind
deriving instance Repr for ClosureBinder
deriving instance Repr for Closure
deriving instance Repr for Guard
deriving instance Repr for MatchArm
deriving instance Repr for AnonConst
deriving instance Repr for MethodCall
deriving instance Repr for StructRest
deriving instance Repr for StructExpr
deriving instance Repr for ExprField
deriving instance Repr for LocalKind
deriving instance Repr for Local
deriving instance Repr for MacroCallStmt
deriving instance Repr for Stmt
deriving instance Repr for MacCall
deriving instance Repr for FormatArgs
deriving instance Repr for FormatArgument
deriving instance Repr for FnContract
deriving instance Repr for FnDecl
deriving instance Repr for FnSig
deriving instance Repr for Fn
deriving instance Repr for ConstItemRhsKind
deriving instance Repr for ConstItem
deriving instance Repr for StaticItem
deriving instance Repr for TyAlias
deriving instance Repr for ForeignMod
deriving instance Repr for ModKind
deriving instance Repr for RestrictionKind
deriving instance Repr for TraitAlias
deriving instance Repr for Trait
deriving instance Repr for TraitImplHeader
deriving instance Repr for Impl
deriving instance Repr for InlineAsmSym
deriving instance Repr for InlineAsmOperand
deriving instance Repr for InlineAsm
deriving instance Repr for Delegation
deriving instance Repr for DelegationSuffixes
deriving instance Repr for DelegationMac
deriving instance Repr for Item
deriving instance Repr for AssocItemKind
deriving instance Repr for AssocItem
deriving instance Repr for ForeignItemKind
deriving instance Repr for ForeignItem
deriving instance Repr for VariantData
deriving instance Repr for FieldDef
deriving instance Repr for Variant
deriving instance Repr for AttrArgs
deriving instance Repr for AttrItem
deriving instance Repr for AttrKind
deriving instance Repr for Attribute
