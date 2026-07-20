module

public import LeanRustParser.Basic.NonMutual
public import LeanRustParser.Basic.Mutual

@[expose] public section

/-! Structural equality instances for the current mutually-recursive
`rustc_ast` source-tree representation.  These deliberately name no removed
compatibility AST types. -/

/-- `MacroDef` is defined outside the recursive AST because its body is a
macro-token stream.  Its equality is nevertheless needed while deriving the
recursive `Item` equality below, so define it explicitly rather than asking
the deriving handler to discover it through `Item.macroDef`. -/
instance : BEq MacroDef where
  beq left right := left.body == right.body && left.macroRules == right.macroRules

deriving instance BEq for Path
deriving instance BEq for PathSegment
deriving instance BEq for Visibility
deriving instance BEq for UseTreeKind
deriving instance BEq for UseTree
deriving instance BEq for GenericArgs
deriving instance BEq for GenericArg
deriving instance BEq for AngleBracketedArg
deriving instance BEq for AssocItemConstraint
deriving instance BEq for Term
deriving instance BEq for AssocItemConstraintKind
deriving instance BEq for QSelf
deriving instance BEq for Ty
deriving instance BEq for MutTy
deriving instance BEq for FnPtrTy
deriving instance BEq for UnsafeBinderTy
deriving instance BEq for TyPat
deriving instance BEq for TraitRef
deriving instance BEq for PolyTraitRef
deriving instance BEq for GenericBound
deriving instance BEq for PreciseCapturingArg
deriving instance BEq for Block
deriving instance BEq for WhereClause
deriving instance BEq for WherePred
deriving instance BEq for WherePredKind
deriving instance BEq for Generics
deriving instance BEq for GenericParam
deriving instance BEq for Param
deriving instance BEq for PatField
deriving instance BEq for Pat
deriving instance BEq for Expr
deriving instance BEq for ExprKind
deriving instance BEq for YieldKind
deriving instance BEq for ClosureBinder
deriving instance BEq for Closure
deriving instance BEq for Guard
deriving instance BEq for MatchArm
deriving instance BEq for AnonConst
deriving instance BEq for MethodCall
deriving instance BEq for StructRest
deriving instance BEq for StructExpr
deriving instance BEq for ExprField
deriving instance BEq for LocalKind
deriving instance BEq for Local
deriving instance BEq for MacroCallStmt
deriving instance BEq for Stmt
deriving instance BEq for MacCall
deriving instance BEq for FormatArgs
deriving instance BEq for FormatArgument
deriving instance BEq for FnContract
deriving instance BEq for FnDecl
deriving instance BEq for FnSig
deriving instance BEq for Fn
deriving instance BEq for ConstItemRhsKind
deriving instance BEq for ConstItem
deriving instance BEq for StaticItem
deriving instance BEq for TyAlias
deriving instance BEq for ForeignMod
deriving instance BEq for ModKind
deriving instance BEq for RestrictionKind
deriving instance BEq for TraitAlias
deriving instance BEq for Trait
deriving instance BEq for TraitImplHeader
deriving instance BEq for Impl
deriving instance BEq for InlineAsmSym
deriving instance BEq for InlineAsmOperand
deriving instance BEq for InlineAsm
deriving instance BEq for Delegation
deriving instance BEq for DelegationSuffixes
deriving instance BEq for DelegationMac
deriving instance BEq for Item
deriving instance BEq for AssocItemKind
deriving instance BEq for AssocItem
deriving instance BEq for ForeignItemKind
deriving instance BEq for ForeignItem
deriving instance BEq for VariantData
deriving instance BEq for FieldDef
deriving instance BEq for Variant
deriving instance BEq for AttrArgs
deriving instance BEq for AttrItem
deriving instance BEq for AttrKind
deriving instance BEq for Attribute
