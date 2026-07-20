module

public import LeanRustParser.Basic.NonMutual

@[expose] public section

/-! ──────────────────────────────────────────────────────────────
    § 2  Mutually recursive AST
        (Literal, Path, Ty, TraitBoundItem, GenericArgs,
         Block, Expr, Pat, Stmt, Item, …)
──────────────────────────────────────────────────────────────── -/

-- We vastly increase heartbeats because deriving `Repr` for 40+ highly mutually
-- recursive inductive types requires immense traversal limits in Lean 4's typeclass synthesis.
-- set_option maxHeartbeats 0


/-! ──────────────────────────────────────────────────────────────
    § 2  Mutually recursive AST
        (Literal, Path, Ty, TraitBoundItem, GenericArgs,
         Block, Expr, Pat, Stmt, Item, …)
──────────────────────────────────────────────────────────────── -/

set_option maxHeartbeats 20000000

mutual
  /-- `rustc_ast::Path`, without span or cached tokens. -/
  structure Path where
    /-- Whether this path started with `::`.  rustc encodes this as its special
    `kw::PathRoot` first segment; retaining it explicitly avoids inventing an
    identifier that was not present in source. -/
    isGlobal : Bool
    segments : List PathSegment

  /-- `rustc_ast::PathSegment`, without node ID. -/
  structure PathSegment where
    ident : Ident
    args : Option GenericArgs

  /-- Joint representation of `rustc_ast::Visibility` and `VisibilityKind`.
  The outer Rust structure has only `kind` after ID/span/token metadata is
  omitted, so retaining a wrapper would add no source information.  Restricted
  visibility uses rustc's normalized path plus `shorthand` representation. -/
  inductive Visibility
    | public_
    | restricted_ (path : Path) (shorthand : Bool)
    | inherited

  /-- `rustc_ast::UseTreeKind`, without braces/glob spans or nested node IDs. -/
  inductive UseTreeKind
    | simple (rename : Option Ident)
    | nested (items : List UseTree)
    | glob

  /-- `rustc_ast::UseTree`, without spans.  Keeping the complete prefix as a
  `Path` avoids flattening imports into a linked identifier chain.  Lean
  reserves `prefix`, so `prefix_` is rustc's `UseTree.prefix`. -/
  structure UseTree where
    prefix_ : Path
    kind : UseTreeKind

  /-- `rustc_ast::GenericArgs`, without spans. `AngleBracketedArgs` contains
  only its span plus `args`, so the angle-bracketed constructor's list directly
  implements both `rustc_ast::AngleBracketedArgs` and its payload. Likewise,
  parenthesized fields directly implement `ParenthesizedArgs` after its spans
  and `FnRetTy::Default` insertion span are omitted. -/
  inductive GenericArgs
    | angleBracketed (args : List AngleBracketedArg)
    | parenthesized (inputs : List Ty) (output : Option Ty)
    | parenthesizedElided

  /-- `rustc_ast::GenericArg`. -/
  inductive GenericArg
    | lifetime (lifetime : Lifetime)
    | ty (ty : Ty)
    | const_ (anonConst : AnonConst)

  /-- `rustc_ast::AngleBracketedArg`. -/
  inductive AngleBracketedArg
    | arg (arg : GenericArg)
    | constraint (constraint : AssocItemConstraint)

  /-- `rustc_ast::AssocItemConstraint`, without spans. -/
  structure AssocItemConstraint where
    ident : Ident
    genArgs : Option GenericArgs
    kind : AssocItemConstraintKind

  /-- `rustc_ast::Term`.  This two-case union carries source syntax, so unlike
  a one-field wrapper it cannot be joined into its use site. -/
  inductive Term
    | ty (value : Ty)
    | const_ (value : AnonConst)

  /-- `rustc_ast::AssocItemConstraintKind`, without punctuation spans. -/
  inductive AssocItemConstraintKind
    | equality (term : Term)
    | bound (bounds : List GenericBound)

  /-- Qualified-self syntax `<Ty as Trait>::Assoc`.
  Rust stores the trait path and suffix in one flattened `Path`, then uses a
  numeric `position` metadata field to split it.  This source tree keeps the
  boundary directly instead. -/
  structure QSelf where
    ty : Ty
    trait_ : Option Path
    -- Omitted: rustc's `position : usize` is redundant split metadata for its
    -- flattened path encoding; it is not source syntax and is not needed when
    -- `trait_` is stored explicitly.
    -- position : Nat

  /-- Joint representation of `rustc_ast::Ty` and `rustc_ast::TyKind`.
  Rust's outer `Ty` contributes only node ID, span, and cached tokens; all are
  intentionally omitted in this source tree, so a wrapper around `kind` would
  add no source information. -/
  inductive Ty
    | slice (ty : Ty)
    | array (ty : Ty) (len : AnonConst)
    | ptr (mutTy : MutTy)
    | ref (lifetime : Option Lifetime) (mutTy : MutTy)
    | pinnedRef (lifetime : Option Lifetime) (mutTy : MutTy)
    | fnPtr (fnPtr : FnPtrTy)
    | unsafeBinder (binder : UnsafeBinderTy)
    | never
    | tuple (tys : List Ty)
    | path (qself : Option QSelf) (path : Path)
    | traitObject (bounds : List GenericBound) (syntax_ : TraitObjectSyntax)
    /-- Rust additionally stores a node ID here so AST lowering can reuse it.
    That ID is compiler bookkeeping, so only source bounds are retained. -/
    | implTrait (bounds : List GenericBound)
    | paren (ty : Ty)
    | infer
    | implicitSelf
    | macCall (mac : MacCall)
    | cVarArgs
    | pat (ty : Ty) (pat : TyPat)
    | fieldOf (ty : Ty) (enumVariant : Option Ident) (field : Ident)

  /-- `rustc_ast::MutTy`, without span. -/
  structure MutTy where
    ty : Ty
    mutbl : Mutability

  /-- `rustc_ast::FnPtrTy`, without `decl_span`.  Function-pointer types only
  carry safety and extern qualifiers; using `FnHeader` here would incorrectly
  admit `const`, `async`, and `gen`. -/
  structure FnPtrTy where
    safety : Safety
    ext : Extern
    genericParams : List GenericParam
    decl : FnDecl
    -- declSpan : Span

  /-- `rustc_ast::UnsafeBinderTy`, without spans. -/
  structure UnsafeBinderTy where
    genericParams : List GenericParam
    innerTy : Ty

  /-- Joint representation of `rustc_ast::TyPat` and `rustc_ast::TyPatKind`.
  The omitted outer fields are ID, span, and cached tokens.  Diagnostic-only
  recovery variants are also omitted because this is a source syntax tree. -/
  inductive TyPat
    | range (lo : Option AnonConst) (hi : Option AnonConst) (end_ : RangeEnd)
    | notNull
    | or (pats : List TyPat)

  /-- `rustc_ast::TraitRef`, without its node ID. -/
  structure TraitRef where
    path : Path

  /-- `rustc_ast::PolyTraitRef`, without its span. -/
  structure PolyTraitRef where
    boundGenericParams : List GenericParam
    modifiers : TraitBoundModifiers
    traitRef : TraitRef
    parens : Parens

  /-- `rustc_ast::GenericBound`. -/
  inductive GenericBound
    | trait_       (bound : PolyTraitRef)
    | lifetime     (l : Lifetime)
    | use_         (args : List PreciseCapturingArg)  -- `use<'a, T>` precise capturing

  /-- Arguments in a `use<…>` precise-capturing bound. -/
  inductive PreciseCapturingArg
    | lifetime (l : Lifetime)
    | arg      (p : Path)

  /-- A braced block `{ stmt* }`, mirroring `rustc_ast::Block` without node id,
  span, or cached tokens.  A tail expression is the final `Stmt.expr`, exactly
  as in rustc; labels belong to `ExprKind.block`. -/
  structure Block where
    rules : BlockCheckMode
    stmts : List Stmt


  /-- `rustc_ast::WhereClause`, without spans.  `hasWhereToken` is retained:
  `where {}` is distinct source syntax from an absent where clause. -/
  structure WhereClause where
    hasWhereToken : Bool
    predicates : List WherePred

  /-- `rustc_ast::WherePredicate`, without ID/span/placeholder recovery data. -/
  structure WherePred where
    attrs : List Attribute
    kind : WherePredKind

  /-- Source forms of `rustc_ast::WherePredicateKind`. `WhereBoundPredicate`
  and `WhereRegionPredicate` are flattened into their respective constructors:
  their omitted fields are only contained IDs/spans, so these constructors
  directly implement both the kind and payload rustc types. -/
  inductive WherePredKind
    | bound (boundGenerics : List GenericParam) (boundedTy : Ty) (bounds : List GenericBound)
    | lifetime (lifetime : Lifetime) (bounds : List GenericBound)

  /-- `rustc_ast::Generics`, without its span.  Generic parameters and their
  where-clause are one source unit and must not be split across item variants. -/
  structure Generics where
    params : List GenericParam
    whereClause : WhereClause

  /-- `rustc_ast::GenericParam`, without ID/span/placeholder metadata.
  `GenericParamKind` is flattened into these constructors: its fields are
  source fields already retained here, so a separate wrapper adds none. -/
  inductive GenericParam
    | ty       (attrs : List Attribute) (name : Ident) (bounds : List GenericBound) (default_ : Option Ty)
    | lifetime (attrs : List Attribute) (lt : Lifetime) (bounds : List GenericBound)
    | const_   (attrs : List Attribute) (name : Ident) (ty : Ty) (default_ : Option AnonConst)
    -- Omitted: macro-expansion metavariables are not source Rust syntax.
    -- | metavar (name : String)

  /-- `rustc_ast::Param`, without ID, span, and placeholder recovery state.
  `self` is represented by an identifier pattern and `Ty.implicitSelf` (or a
  reference to it), as rustc does; it is not a separate parameter variant. -/
  structure Param where
    attrs : List Attribute
    pat : Pat
    ty : Ty

  /-- `rustc_ast::PatField`, without ID, span, or cached tokens. -/
  structure PatField where
    attrs : List Attribute
    ident : Ident
    pat : Pat
    isShorthand : Bool

  /-- Joint representation of `rustc_ast::Pat` and `rustc_ast::PatKind`.
  Rust's outer `Pat` carries only ID, span, and cached tokens, intentionally
  omitted here.  Diagnostic-recovery variants are likewise not source syntax. -/
  inductive Pat
    -- Omitted: `PatKind::Missing` is parser-recovery state for malformed
    -- input, not valid source syntax.
    -- | missing
    | wild
    | ident (mode : BindingMode) (ident : Ident) (subpat : Option Pat)
    | struct_ (qself : Option QSelf) (path : Path) (fields : List PatField) (pfrest : PatFieldsRest)
    | tupleStruct (qself : Option QSelf) (path : Path) (pats : List Pat)
    | or (pats : List Pat)
    | path (qself : Option QSelf) (path : Path)
    | tuple (pats : List Pat)
    | box_ (pat : Pat)
    | deref (pat : Pat)
    | ref (pat : Pat) (pinnedness : Pinnedness) (mutbl : Mutability)
    | expr (expr : Expr)
    | range (lo : Option Expr) (hi : Option Expr) (end_ : RangeEnd)
    | slice (pats : List Pat)
    | rest
    | never
    | guard (pat : Pat) (guard : Guard)
    | paren (pat : Pat)
    | macCall (mac : MacCall)

  /-- `rustc_ast::Expr`: attributes belong to the expression, not its statement. -/
  structure Expr where
    attrs : List Attribute
    kind : ExprKind

  /-- `rustc_ast::ExprKind`. -/
  inductive ExprKind
    -- Literals & paths
    | literal    (l : Lit)
    | path       (qself : Option QSelf) (path : Path)
    -- Omitted: macro metavariables are expansion/interpolation state, not
    -- source `rustc_ast::ExprKind` syntax.
    -- | metavar (name : String)
    | underscore                               -- `_` in destructuring assignment
    -- Operators
    | unary      (op : UnOp) (e : Expr)
    | binary     (op : BinOpKind) (l r : Expr)
    | assign     (l r : Expr)
    | compoundAssign (op : BinOpKind) (l r : Expr)
    | cast       (e : Expr) (ty : Ty)
    | type_      (e : Expr) (ty : Ty)         -- type ascription `e: T`
    | try_       (e : Expr)                   -- `e?`
    | range      (lo : Option Expr) (hi : Option Expr) (limits : RangeLimits)
    -- Calls & field access
    | call       (fn_ : Expr) (args : List Expr)
    | methodCall (call : MethodCall)
    | field      (recv : Expr) (field : Ident)
    | index      (recv : Expr) (idx : Expr)
    | await      (e : Expr)
    -- Move / become / error propagation
    | move_      (e : Expr)                   -- `move e` (nightly)
    | become     (e : Expr)                   -- `become f()` (tail calls, nightly)
    | yeet       (e : Option Expr)            -- `do yeet e` (nightly)
    -- Closures & blocks
    | closure    (closure : Closure)
    | block      (b : Block) (label : Option Label)
    | genBlock   (capture : CaptureBy) (b : Block) (kind : GenBlockKind)
    | tryBlock   (b : Block) (ty : Option Ty) -- `try { ... }`
    | constBlock (anonConst : AnonConst)
    -- Control flow
    /-- `Recovered` is an error-recovery diagnostic payload, deliberately
    omitted from the source tree. -/
    | let_       (pat : Pat) (val : Expr)
    | if_        (cond : Expr) (then_ : Block) (else_ : Option Expr)
    | match_     (val : Expr) (arms : List MatchArm) (kind : MatchKind)
    | while_     (label : Option Label) (cond : Expr) (body : Block)
    | loop_      (label : Option Label) (body : Block)
    | for_       (label : Option Label) (pat : Pat) (iter : Expr) (body : Block)
                 (kind : ForLoopKind)
    | return_    (val : Option Expr)
    | yield_     (kind : YieldKind)
    | break_     (label : Option Label) (val : Option Expr)
    | continue_  (label : Option Label)
    -- Use expression (precise capturing, nightly)
    | use_       (e : Expr)
    -- Constructors
    | array      (elems : List Expr)
    | repeat     (elem : Expr) (len : AnonConst)
    | tuple      (elems : List Expr)
    | struct_    (structExpr : StructExpr)
    | paren      (e : Expr)                   -- parenthesised expression
    -- Generics & macros
    | macCall    (mac : MacCall)
    | formatArgs (args : FormatArgs)
    -- Assembly & builtins
    | inlineAsm  (asm : InlineAsm)
    | offsetOf   (ty : Ty) (fields : List Ident)      -- `offset_of!(T, f)`
    | includedBytes (bytes : ByteSymbol)
    -- References
    | addrOf     (borrow : BorrowKind) (mutbl : Mutability) (e : Expr)
    -- Unsafe binder cast (nightly)
    | unsafeBinderCast (kind : UnsafeBinderCastKind) (e : Expr) (ty : Option Ty)
    -- Omitted: compiler placeholders used only after error recovery/lowering.
    -- | dummy
    -- | err        (error : ErrorGuaranteed)

  /-- `rustc_ast::YieldKind`, without spans.  It is recursive because rustc
  owns the yielded expression inside this enum, rather than beside it. -/
  inductive YieldKind
    | prefix (value : Option Expr)
    | postfix (value : Expr)

  /-- `rustc_ast::ClosureBinder`, without binder spans. -/
  inductive ClosureBinder
    | notPresent
    | for_ (genericParams : List GenericParam)

  /-- Source-level `rustc_ast::Closure`, without ID/span and compiler-only
  desugaring metadata.  A block body is itself an `ExprKind.block`; keeping one
  `Expr` body matches rustc and removes the project-specific body split. -/
  structure Closure where
    binder : ClosureBinder
    captureClause : CaptureBy
    constness : Const
    coroutineKind : Option CoroutineKind
    movability : Movability
    fnDecl : FnDecl
    body : Expr
    -- fnDeclSpan : Span
    -- fnArgSpan : Span

  /-- `rustc_ast::Guard`, without `span_with_leading_if`. -/
  structure Guard where
    cond : Expr

  /-- `rustc_ast::Arm`, without ID, span, and placeholder recovery state.
  `body = none` is required for never-pattern arms; `is_placeholder` is a
  parser-recovery marker and deliberately not source-tree data. -/
  structure MatchArm where
    attrs : List Attribute
    pat : Pat
    guard : Option Guard
    body : Option Expr

  /-- `rustc_ast::AnonConst`, without ID, span, or disambiguation metadata. -/
  structure AnonConst where
    value : Expr

  /-- `rustc_ast::MethodCall`, without span. -/
  structure MethodCall where
    seg : PathSegment
    receiver : Expr
    args : List Expr

  /-- `rustc_ast::StructRest`, omitting only the error payload span. -/
  inductive StructRest
    | base (expr : Expr)
    | rest
    | none
    -- Omitted: recovery-only distinction used to suppress follow-up
    -- diagnostics after a struct-literal parse error.
    -- | noneWithError (error : ErrorGuaranteed)

  /-- `rustc_ast::StructExpr`, without spans. -/
  structure StructExpr where
    qself : Option QSelf
    path : Path
    fields : List ExprField
    rest : StructRest

  /-- `rustc_ast::ExprField`, without ID, span, or placeholder recovery state. -/
  structure ExprField where
    attrs : List Attribute
    ident : Ident
    expr : Expr
    isShorthand : Bool

  /-- `rustc_ast::LocalKind`, without `=` spans.  Separating these cases keeps
  invalid states such as `else` without an initializer unrepresentable. -/
  inductive LocalKind
    | decl
    | init (value : Expr)
    | initElse (value : Expr) (else_ : Block)

  /-- `rustc_ast::Local`, without ID, spans, or cached tokens.  `super_`
  retains whether the source contained the `super` keyword; only its span is
  omitted. Mutability belongs in the binding pattern, not on the local itself. -/
  structure Local where
    super_ : Bool
    attrs : List Attribute
    pat : Pat
    ty : Option Ty
    kind : LocalKind

  /-- `rustc_ast::MacCallStmt`. -/
  structure MacroCallStmt where
    attrs : List Attribute
    mac : MacCall
    style : MacStmtStyle

  /-- Joint representation of `rustc_ast::Stmt` and `rustc_ast::StmtKind`.
  Rust's outer `Stmt` contributes only node id and span, both intentionally
  omitted here, so a separate wrapper would add no information. -/
  inductive Stmt
    | expr    (e : Expr)                       -- expression without trailing `;`
    | semi    (e : Expr)                       -- expression with trailing `;`
    | let_    (_local : Local)
    | item    (it : Item)
    | macCall (stmt : MacroCallStmt)
    | empty

  /-- `rustc_ast::MacCall`, without spans. -/
  structure MacCall where
    path : Path
    args : DelimArgs

  /-- `rustc_ast::FormatArgs`, without its span. `FormatArguments` is joined
  into its `List FormatArgument` wrappee because its remaining rustc fields
  (`names`, `num_unnamed_args`, and `num_explicit_args`) are lookup/count
  caches derived from that list. `is_source_literal` is expansion provenance,
  not source syntax, and is intentionally omitted. -/
  structure FormatArgs where
    template : List FormatArgsPiece
    arguments : List FormatArgument
    uncookedFmtStr : LitKind × String
    -- isSourceLiteral : Bool

  /-- `rustc_ast::FormatArgument`, without boxing. -/
  structure FormatArgument where
    kind : FormatArgumentKind
    expr : Expr

  /-- `rustc_ast::FnContract`, without spans. -/
  structure FnContract where
    declarations : List Stmt
    requires : Option Expr
    ensures : Option Expr

  /-- `rustc_ast::FnDecl`, without spans.  Its `FnRetTy` output wrapper has no
  source payload in its default case after the insertion span is omitted, so
  `Option Ty` directly implements both `FnRetTy` and its useful payload. -/
  structure FnDecl where
    inputs : List Param
    output : Option Ty

  /-- `rustc_ast::FnSig`, without its span. -/
  structure FnSig where
    header : FnHeader
    decl : FnDecl

  /-- `rustc_ast::Fn`, without spans. `define_opaque` is lowering bookkeeping
  and `eii_impls` is post-attribute-expansion/name-resolution state, so both
  are deliberately omitted from this source tree. -/
  structure Fn where
    defaultness : Defaultness
    ident : Ident
    generics : Generics
    sig : FnSig
    contract : Option FnContract
    body : Option Block
    -- defineOpaque : Option (List Path)
    -- eiiImpls : List EiiImpl

  /-- `rustc_ast::ConstItemRhsKind`, without `=`/expression spans. -/
  inductive ConstItemRhsKind
    | body (rhs : Option Expr)
    | typeConst (rhs : Option AnonConst)

  /-- `rustc_ast::ConstItem`, without spans. `define_opaque` is lowering
  bookkeeping and is intentionally omitted. -/
  structure ConstItem where
    defaultness : Defaultness
    ident : Ident
    generics : Generics
    ty : Ty
    rhsKind : ConstItemRhsKind
    -- defineOpaque : Option (List Path)

  /-- `rustc_ast::StaticItem`, without spans. `define_opaque` and `eii_impls`
  are lowering/name-resolution metadata and are intentionally omitted. -/
  structure StaticItem where
    ident : Ident
    ty : Ty
    safety : Safety
    mutability : Mutability
    expr : Option Expr
    -- defineOpaque : Option (List Path)
    -- eiiImpls : List EiiImpl

  /-- `rustc_ast::TyAlias`, without spans. The second where-clause is source
  syntax distinct from `Generics.whereClause`, so it is retained. -/
  structure TyAlias where
    defaultness : Defaultness
    ident : Ident
    generics : Generics
    afterWhereClause : WhereClause
    bounds : List GenericBound
    ty : Option Ty

  /-- `rustc_ast::ForeignMod`, without the `extern` span. -/
  structure ForeignMod where
    safety : Safety
    abi : Option StrLit
    items : List ForeignItem

  /-- `rustc_ast::ModKind`, without `ModSpans`.  The loaded state must retain
  whether its source was inline or was loaded from an outlined module. -/
  inductive ModKind
    | loaded (items : List Item) (inline : Inline)
    | unloaded

  /-- `rustc_ast::RestrictionKind`, without the restricted-path node ID. -/
  inductive RestrictionKind
    | unrestricted
    | restricted (path : Path) (shorthand : Bool)

  /-- `rustc_ast::TraitAlias`, without spans. -/
  structure TraitAlias where
    constness : Const
    ident : Ident
    generics : Generics
    bounds : List GenericBound

  /-- `rustc_ast::Trait`, without spans. -/
  structure Trait where
    /-- `rustc_ast::ImplRestriction` is only a `RestrictionKind` wrapper once
    span/tokens are omitted, so this field directly implements both types. -/
    implRestriction : RestrictionKind
    constness : Const
    safety : Safety
    isAuto : IsAuto
    ident : Ident
    generics : Generics
    bounds : List GenericBound
    items : List AssocItem

  /-- `rustc_ast::TraitImplHeader`, without spans. -/
  structure TraitImplHeader where
    defaultness : Defaultness
    safety : Safety
    polarity : ImplPolarity
    traitRef : TraitRef

  /-- `rustc_ast::Impl`, without spans. -/
  structure Impl where
    generics : Generics
    constness : Const
    ofTrait : Option TraitImplHeader
    selfTy : Ty
    items : List AssocItem

  /-- `rustc_ast::InlineAsmSym`, without node ID. -/
  structure InlineAsmSym where
    qself : Option QSelf
    path : Path

  /-- `rustc_ast::InlineAsmOperand`, without operand spans. -/
  inductive InlineAsmOperand
    | in_        (reg : InlineAsmRegOrRegClass) (expr : Expr)
    | out        (reg : InlineAsmRegOrRegClass) (late : Bool) (expr : Option Expr)
    | inOut      (reg : InlineAsmRegOrRegClass) (late : Bool) (expr : Expr)
    | splitInOut (reg : InlineAsmRegOrRegClass) (late : Bool)
                 (inExpr : Expr) (outExpr : Option Expr)
    | const_     (anonConst : AnonConst)
    | sym_       (sym : InlineAsmSym)
    | label_     (block : Block)

  /-- `rustc_ast::InlineAsm`, without operand/template/clobber/line spans.
  Those spans only locate already-retained source payload; `templateStrs`,
  operands, and clobber ABIs therefore store their non-span wrappees directly. -/
  structure InlineAsm where
    asmMacro : AsmMacro
    template : List InlineAsmTemplatePiece
    templateStrs : List (String × Option String)
    operands : List InlineAsmOperand
    clobberAbis : List String
    options : InlineAsmOptions

  /-- `rustc_ast::Delegation`, without node IDs and spans. `source` retains
  its source form; rustc's `LocalExpnId` payload for list delegation is omitted
  as expansion metadata. -/
  structure Delegation where
    qself : Option QSelf
    path : Path
    ident : Ident
    rename : Option Ident
    body : Option Block
    source : DelegationSource

  /-- `rustc_ast::DelegationMac`, without spans. -/
  structure DelegationMac where
    qself : Option QSelf
    prefix_ : Path
    suffixes : DelegationSuffixes
    body : Option Block

  /-- Joint representation of `rustc_ast::Item` and `rustc_ast::ItemKind`.
  Rust's outer `Item` distributes `attrs`, `vis`, and `ident` across the
  relevant item kinds. This Lean enum keeps those source fields directly in
  each constructor, rather than adding a wrapper containing only `kind`. -/
  inductive Item
    -- Modules
    | mod        (attrs : List Attribute) (vis : Visibility) (safety : Safety)
                 (name : Ident) (kind : ModKind)
    | foreignMod (attrs : List Attribute) (vis : Visibility) (foreignMod : ForeignMod)
    -- Type definitions
    | struct_    (attrs : List Attribute) (vis : Visibility)
                 (name : Ident) (generics : Generics) (body : VariantData)
    | union_     (attrs : List Attribute) (vis : Visibility)
                 (name : Ident) (generics : Generics) (body : VariantData)
    /-- `EnumDef` is only a `variants` wrapper, so this list directly
    implements both `rustc_ast::EnumDef` and its `variants` field. -/
    | enum_      (attrs : List Attribute) (vis : Visibility)
                 (name : Ident) (generics : Generics) (variants : List Variant)
    | typeAlias  (attrs : List Attribute) (vis : Visibility) (alias : TyAlias)
    | traitAlias (attrs : List Attribute) (vis : Visibility) (alias : TraitAlias)
    -- Functions
    | fn_        (attrs : List Attribute) (vis : Visibility) (function : Fn)
    -- Traits & impls
    | trait_     (attrs : List Attribute) (vis : Visibility) (trait : Trait)
    | impl_      (attrs : List Attribute) (vis : Visibility) (impl_ : Impl)
    -- Values & statics
    | const_     (attrs : List Attribute) (vis : Visibility) (constant : ConstItem)
    /-- `ConstBlockItem` contains only ID/span plus `block`; this payload
    directly implements both `rustc_ast::ConstBlockItem` and `Block`. -/
    | constBlock (attrs : List Attribute) (vis : Visibility) (block : Block)
    | static_    (attrs : List Attribute) (vis : Visibility) (static : StaticItem)
    -- Use & extern
    | use_       (attrs : List Attribute) (vis : Visibility) (tree : UseTree)
    | externCrate (attrs : List Attribute) (vis : Visibility)
                  (originalName : Option String) (name : Ident)
    -- Attributes belong to the owning item/statement/expression, as in rustc.
    | macro_     (attrs : List Attribute) (vis : Visibility) (inv : MacCall)
    | macroDef   (attrs : List Attribute) (vis : Visibility) (name : Ident) (definition : MacroDef)
    -- Assembly & delegation
    | globalAsm    (attrs : List Attribute) (vis : Visibility) (asm : InlineAsm)
    | delegation   (attrs : List Attribute) (vis : Visibility) (delegation : Delegation)
    | delegationMac (attrs : List Attribute) (vis : Visibility) (delegation : DelegationMac)

  /-- `rustc_ast::AssocItemKind`. -/
  inductive AssocItemKind
    | const_ (item : ConstItem)
    | fn_ (item : Fn)
    | typeAlias (item : TyAlias)
    | macCall (mac : MacCall)
    | delegation (item : Delegation)
    | delegationMac (item : DelegationMac)

  /-- `rustc_ast::AssocItem`, which is the same outer `Item<AssocItemKind>`
  representation used for both rustc `TraitItem` and `ImplItem`. Node ID,
  span, and cached tokens are metadata and are intentionally omitted. -/
  structure AssocItem where
    attrs : List Attribute
    vis : Visibility
    kind : AssocItemKind

  /-- `rustc_ast::ForeignItemKind`. -/
  inductive ForeignItemKind
    | static_ (item : StaticItem)
    | fn_ (item : Fn)
    | typeAlias (item : TyAlias)
    | macCall (mac : MacCall)

  /-- `rustc_ast::ForeignItem`, an `Item<ForeignItemKind>` without node ID,
  span, and cached tokens. -/
  structure ForeignItem where
    attrs : List Attribute
    vis : Visibility
    kind : ForeignItemKind

  /-- `rustc_ast::VariantData`, without constructor IDs and recovery payloads.
  `Recovered` is diagnostic state, so only the fields remain in the record
  variant. -/
  inductive VariantData
    | unit
    | tuple  (fields : List FieldDef)
    | record (fields : List FieldDef)

  /-- `rustc_ast::FieldDef`, without ID, span, cached tokens, and placeholder
  recovery state.  Tuple
  fields have `ident = none`; record fields have `ident = some name`. -/
  structure FieldDef where
    attrs : List Attribute
    vis : Visibility
    /-- `rustc_ast::MutRestriction` is only an outer wrapper around
    `RestrictionKind` once span/tokens are omitted, so this field directly
    implements both rustc types. -/
    mutRestriction : RestrictionKind
    safety : Safety
    ident : Option Ident
    ty : Ty
    default_ : Option AnonConst

  /-- `rustc_ast::Variant`, without ID, span, or placeholder recovery state. -/
  structure Variant where
    attrs : List Attribute
    vis : Visibility
    ident : Ident
    data : VariantData
    disrExpr : Option AnonConst

  /-- `rustc_ast::AttrArgs`, without the `=` span. -/
  inductive AttrArgs
    | empty
    | delimited (args : DelimArgs)
    | eq (expr : Expr)

  /-- `rustc_ast::AttrItem`, without cached tokens.
  Rust's `AttrItemKind::Parsed(EarlyParsedAttribute)` is a performance cache;
  with it intentionally omitted, the remaining `Unparsed(AttrArgs)` would be
  an information-free wrapper, so `args` stores `AttrArgs` directly. -/
  structure AttrItem where
    unsafety : Safety
    path : Path
    args : AttrArgs

  /-- `rustc_ast::AttrKind`.  `NormalAttr` contains only `AttrItem` after its
  cached token stream is intentionally omitted, so it is joined here rather
  than retained as an information-free wrapper. -/
  inductive AttrKind
    | normal (item : AttrItem)
    | docComment (kind : CommentKind) (symbol : String)

  /-- `rustc_ast::Attribute`, without ID, span, or cached tokens. -/
  structure Attribute where
    kind : AttrKind
    style : AttrStyle

end  -- mutual
