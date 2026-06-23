module

public import LeanRustParser.Basic.NonMutual

@[expose] public section

/-! ──────────────────────────────────────────────────────────────
    § 2  Mutually recursive AST
        (Literal, ScopedPath, Ty, TraitBound, TypeArgs,
         Block, Expr, Pat, Stmt, Item, …)
──────────────────────────────────────────────────────────────── -/

-- We vastly increase heartbeats because deriving `Repr` for 40+ highly mutually
-- recursive inductive types requires immense traversal limits in Lean 4's typeclass synthesis.
-- set_option maxHeartbeats 0


/-! ──────────────────────────────────────────────────────────────
    § 2  Mutually recursive AST
        (Literal, ScopedPath, Ty, TraitBound, TypeArgs,
         Block, Expr, Pat, Stmt, Item, …)
──────────────────────────────────────────────────────────────── -/

set_option maxHeartbeats 20000000

mutual
  /-- A path for scoped resolution, e.g. `std::collections::HashMap`.
      Covers both simple identifiers and fully qualified paths including
      `<T as Trait>::Assoc` (QSelf). -/
  inductive ScopedPath
    | self_
    | super_
    | crate_
    | ident      (id : Ident)
    | scoped     (head : ScopedPath) (seg : Ident)
    | generic    (head : ScopedPath) (args : TypeArgs)
    | bracketed  (inner : Ty)
    -- Qualified path  <Ty as Trait>::seg  (QSelf in syn)
    | qpath      (qself : Ty) (trait_ : Option ScopedPath) (seg : Ident)

  /-- Type arguments `<A, B, 'a, const N, Item = T>`. -/
  inductive TypeArgs
    | args (items : List TypeArgItem)

  inductive TypeArgItem
    | ty         (t : Ty)
    | lifetime   (l : Lifetime)
    | binding    (name : Ident) (t : Ty)      -- `Item = T`
    | assocConst (name : Ident) (val : Expr)  -- `PANIC = false`
    | constraint (name : Ident) (bounds : TraitBound) -- `Item: Display`
    | literal    (lit : Literal)
    | block      (b : Block)
    | infer                                   -- `_`

  /-- A Rust type. -/
  inductive Ty
    | primitive    (p : PrimitiveType)
    | named        (id : Ident)
    | scoped       (path : Option ScopedPath) (name : Ident)
    | path         (sp : ScopedPath)           -- general qualified path type
    | generic      (ty : Ty) (args : TypeArgs)
    | reference    (lt : Option Lifetime) (mutbl : Bool) (inner : Ty)
    | pinnedRef    (lt : Option Lifetime) (mutbl : Bool) (inner : Ty) -- `&pin const/mut T` (nightly)
    | pointer      (isConst : Bool) (inner : Ty)  -- `*const T` / `*mut T`
    | array        (elem : Ty) (len : Option Expr)
    | slice        (elem : Ty)
    | tuple        (elems : List Ty)
    | unit                                     -- `()`
    | never                                    -- `!`
    | infer                                    -- `_`
    | paren        (inner : Ty)                -- `(T)` parenthesised
    | fn_          (mods : FnModifiers) (params : List BareFnArg) (ret : Option Ty)
    | implTrait    (bounds : List TraitBoundItem)
    | dynTrait     (bounds : List TraitBoundItem)
    | unsafeBinder (params : TypeParams) (inner : Ty) -- `unsafe<'a> &'a ()` (nightly)
    | pat          (ty : Ty) (pat : Pat)       -- pattern types (nightly)
    | fieldOf      (ty : Ty) (enum_var : Option Ident) (field : Ident) -- `builtin # field_of(...)`
    | cVarArgs                                 -- `...` in variadic foreign fns
    | implicitSelf                             -- implicit `self` type
    | metavar      (name : String)
    | macro_       (inv : MacroInvocation)
    | group        (inner : Ty)                -- invisible delimiter group
    | dummy
    | err

  /-- A bare function argument `name: Ty` in a `fn(…)` type. -/
  inductive BareFnArg
    | named    (name : Option Ident) (ty : Ty)
    | variadic (name : Option Ident)           -- `...`

  /-- A trait bound: the items after `:` in `T: Trait + 'a + use<'b>`. -/
  inductive TraitBound
    | bounds (items : List TraitBoundItem)

  inductive TraitBoundItem
    | trait_       (modifier : TraitBoundModifier) (forLts : List Lifetime) (t : Ty)
    | lifetime     (l : Lifetime)
    | use_         (args : List PreciseCapturingArg)  -- `use<'a, T>` precise capturing

  /-- Arguments in a `use<…>` precise-capturing bound. -/
  inductive PreciseCapturingArg
    | lifetime (l : Lifetime)
    | arg      (p : ScopedPath)

  /-- A braced block `{ stmt* expr? }`. -/
  inductive Block
    | mk (label : Option Label) (stmts : List Stmt) (tail : Option Expr)


  /-- A where-clause predicate. -/
  inductive WherePred
    | ty       (lhs : Ty) (bounds : TraitBound)
    | lifetime (lt : Lifetime) (bounds : List Lifetime)

  /-- Generic parameters `<T: Trait, 'a, const N: usize>`. -/
  inductive TypeParams
    | params (items : List TypeParamItem)

  inductive TypeParamItem
    | ty       (name : Ident) (bounds : Option TraitBound) (default_ : Option Ty)
    | lifetime (lt : Lifetime) (bounds : Option TraitBound)
    | const_   (name : Ident) (ty : Ty) (default_ : Option ConstParamDefault)
    | metavar  (name : String)

  inductive ConstParamDefault
    | block   (b : Block)
    | ident   (id : Ident)
    | literal (l : Literal)

  /-- A function parameter. -/
  inductive Param
    | named    (mutbl : Bool) (pat : Pat) (ty : Ty)
    | self_    (byRef : Bool) (lt : Option Lifetime) (mutbl : Bool)
    | variadic (pat : Option Pat)
    | anon     (ty : Ty)

  /-- Patterns. -/
  inductive Pat
    | literal    (lit : Literal)
    | ident      (byRef mutbl : Bool) (id : Ident) (bound : Option Pat) -- `ref mut x @ pat`
    | primitive  (p : PrimitiveType)
    | path       (sp : ScopedPath)
    | tuple      (pats : List Pat)
    | tupleStruct (ty : ScopedPath) (pats : List Pat)
    | struct_    (ty : ScopedPath) (fields : List FieldPat) (rest : Bool)
    | slice      (pats : List Pat)
    | reference  (mutbl : Bool) (inner : Pat)
    | range      (lo : Option RangePat) (op : RangeOp) (hi : Option RangePat)
    | or         (alts : List Pat)
    | box_       (inner : Pat)                 -- `box pat` (deprecated)
    | deref      (inner : Pat)                 -- `deref!(pat)` (nightly)
    | never                                    -- `!` (never pattern)
    | paren      (inner : Pat)                 -- `(pat)`
    | guard      (pat : Pat) (cond : Expr)     -- pattern guard (nightly inline guard)
    | rest                                     -- `..`
    | wildcard                                 -- `_`
    | constBlock (b : Block)
    | macro_     (inv : MacroInvocation)
    | err

  inductive RangePat
    | literal (l : Literal)
    | path    (p : ScopedPath)

  inductive FieldPat
    | shorthand (byRef mutbl : Bool) (name : Ident)
    | full      (byRef mutbl : Bool) (name : Ident) (pat : Pat)
    | remaining

  /-- Expressions. -/
  inductive Expr
    -- Literals & paths
    | literal    (l : Literal)
    | ident      (id : Ident)
    | primitive  (p : PrimitiveType)
    | self_
    | path       (sp : ScopedPath)
    | metavar    (name : String)
    | infer                                    -- `_` (inferred value)
    -- Operators
    | unary      (op : UnaryOp) (e : Expr)
    | binary     (op : BinOp) (l r : Expr)
    | assign     (l r : Expr)
    | compoundAssign (op : CompoundOp) (l r : Expr)
    | cast       (e : Expr) (ty : Ty)
    | type_      (e : Expr) (ty : Ty)         -- type ascription `e: T`
    | try_       (e : Expr)                   -- `e?`
    | range      (lo : Option Expr) (op : RangeOp) (hi : Option Expr)
    | range_                                   -- bare `..`
    -- Calls & field access
    | call       (fn_ : Expr) (args : List Expr)
    | methodCall (recv : Expr) (method : Ident) (turbofish : Option TypeArgs) (args : List Expr)
    | field      (recv : Expr) (field : Ident)
    | tupleField (recv : Expr) (idx : Nat)    -- `tup.0`
    | index      (recv : Expr) (idx : Expr)
    | await      (e : Expr)
    -- Move / become / error propagation
    | move_      (e : Expr)                   -- `move e` (nightly)
    | become     (e : Expr)                   -- `become f()` (tail calls, nightly)
    | yeet       (e : Option Expr)            -- `do yeet e` (nightly)
    -- Closures & blocks
    | closure    (isAsync : Bool) (capture : CaptureBy) (params : List ClosureParam)
                 (ret : Option Ty) (body : ClosureBody)
    | block      (b : Block)
    | unsafeBlock (b : Block)
    | genBlock   (capture : CaptureBy) (b : Block) (kind : GenBlockKind)
    | tryBlock   (b : Block) (ty : Option Ty) -- `try { ... }`
    | constBlock (b : Block)
    -- Control flow
    | if_        (cond : Condition) (then_ : Block) (else_ : Option ElseClause)
    | match_     (val : Expr) (arms : List MatchArm) (kind : MatchKind)
    | while_     (label : Option Label) (cond : Condition) (body : Block)
    | loop_      (label : Option Label) (body : Block)
    | for_       (label : Option Label) (pat : Pat) (iter : Expr) (body : Block)
                 (kind : ForLoopKind)
    | return_    (val : Option Expr)
    | yield_     (val : Option Expr) (kind : YieldKind)
    | break_     (label : Option Label) (val : Option Expr)
    | continue_  (label : Option Label)
    -- Use expression (precise capturing, nightly)
    | use_       (e : Expr)
    -- Constructors
    | array      (elems : ArrayExprKind)
    | tuple      (elems : List Expr)
    | unit
    | struct_    (name : StructExprName) (fields : List FieldInit) (base : Option Expr)
    | paren      (e : Expr)                   -- parenthesised expression
    -- Generics & macros
    | genericFn  (fn_ : Expr) (args : TypeArgs)
    | macro_     (inv : MacroInvocation)
    | formatArgs (tt : TokenTree)             -- `format_args!(...)`
    -- Assembly & builtins
    | inlineAsm  (asm : InlineAsm)
    | offsetOf   (ty : Ty) (fields : List Ident)      -- `offset_of!(T, f)`
    | includedBytes (path : String)           -- `include_bytes!(...)`
    -- References
    | reference  (raw : Bool) (mutbl : Bool) (e : Expr)
    -- Unsafe binder cast (nightly)
    | unsafeBinderCast (kind : UnsafeBinderCastKind) (e : Expr) (ty : Option Ty)
    | dummy
    | err

  inductive ArrayExprKind
    | list   (elems : List Expr)
    | repeat (elem : Expr) (len : Expr)

  inductive ClosureParam
    | pat   (p : Pat)
    | typed (p : Pat) (ty : Ty)

  inductive ClosureBody
    | expr  (e : Expr)
    | block (b : Block)
    | hole             -- `_`

  inductive Condition
    | expr    (e : Expr)
    | let_    (pat : Pat) (val : Expr)
    | letChain (items : List LetChainItem)

  inductive LetChainItem
    | expr (e : Expr)
    | let_ (pat : Pat) (val : Expr)

  inductive ElseClause
    | block  (b : Block)
    | elseIf (e : Expr)

  inductive MatchArm
    | mk (attrs : List Attribute) (pat : Pat) (guard : Option Condition) (val : Expr)

  inductive StructExprName
    | named      (id : Ident)
    | scoped     (sp : ScopedPath) (name : Ident)
    | turbofish  (id : Ident) (args : TypeArgs)
    | qpath      (qself : Ty) (trait_ : Option ScopedPath) (seg : Ident)

  inductive FieldInit
    | shorthand (id : Ident)
    | full      (field : Ident) (val : Expr)

  /-- A statement. Mirrors rustc's `StmtKind` exactly. -/
  inductive Stmt
    | expr    (e : Expr)                       -- expression without trailing `;`
    | semi    (e : Expr)                       -- expression with trailing `;`
    | let_    (mutbl : Bool) (pat : Pat) (ty : Option Ty)
              (init : Option Expr) (else_ : Option Block)
    | item    (it : Item)
    | macCall (mac : MacroInvocation) (style : MacStmtStyle)
    | empty

  /-- A macro invocation `path!(tokens)`. -/
  inductive MacroInvocation
    | mk (path : ScopedPath) (tokens : TokenTree)

  /-- Externally implementable items mappings. -/
  inductive EiiImpl
    | mk (path : ScopedPath) (isDefault : Bool)

  /-- Contract logic for function definitions. -/
  inductive FnContract
    | mk (decls : List Stmt) (requires : Option Expr) (ensures : Option Expr)

  /-- Minimal subset of Inline Assembly operands. -/
  inductive InlineAsmOperand
    | in_        (reg : String) (expr : Expr)
    | out        (reg : String) (expr : Option Expr)
    | inOut      (reg : String) (expr : Expr)
    | splitInOut (reg : String) (inExpr : Expr) (outExpr : Option Expr)
    | const_     (expr : Expr)
    | sym_       (path : ScopedPath)
    | label_     (block : Block)

  /-- Inline assembly expression. -/
  inductive InlineAsm
    | mk (template : List String) (operands : List InlineAsmOperand)

  /-- Top-level items. -/
  inductive Item
    -- Modules
    | mod        (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (body : Option (List Item))
    | foreignMod (attrs : List Attribute) (isUnsafe : Bool) (abi : Option String)
                 (items : List ForeignItem)
    -- Type definitions
    | struct_    (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option TypeParams)
                 (where_ : Option (List WherePred)) (body : StructBody)
    | union_     (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option TypeParams)
                 (where_ : Option (List WherePred)) (fields : List FieldDecl)
    | enum_      (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option TypeParams)
                 (where_ : Option (List WherePred)) (variants : List EnumVariant)
    | typeAlias  (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option TypeParams)
                 (where_ : Option (List WherePred)) (ty : Option Ty)
    | traitAlias (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option TypeParams)
                 (bounds : TraitBound)
    -- Functions
    | fn_        (attrs : List Attribute) (vis : Option Visibility)
                 (mods : FnModifiers) (name : Ident)
                 (typeParams : Option TypeParams) (params : List Param)
                 (ret : Option Ty) (where_ : Option (List WherePred))
                 (body : Option Block) (contract : Option FnContract)
                 (eii : List EiiImpl)
    | fnSig      (attrs : List Attribute) (vis : Option Visibility)
                 (mods : FnModifiers) (name : Ident)
                 (typeParams : Option TypeParams) (params : List Param)
                 (ret : Option Ty) (where_ : Option (List WherePred))
                 (contract : Option FnContract)
    -- Traits & impls
    | trait_     (attrs : List Attribute) (vis : Option Visibility)
                 (isUnsafe : Bool) (name : Ident)
                 (typeParams : Option TypeParams) (bounds : Option TraitBound)
                 (where_ : Option (List WherePred)) (items : List TraitItem)
    | impl_      (attrs : List Attribute) (isUnsafe : Bool)
                 (typeParams : Option TypeParams) (traitRef : Option ImplTrait)
                 (ty : Ty) (where_ : Option (List WherePred)) (items : List ImplItem)
    | assocType  (attrs : List Attribute) (name : Ident)
                 (typeParams : Option TypeParams) (bounds : Option TraitBound)
                 (where_ : Option (List WherePred)) (default_ : Option Ty)
    -- Values & statics
    | const_     (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (ty : Ty) (val : Option Expr)
    | constBlock (b : Block)
    | static_    (attrs : List Attribute) (vis : Option Visibility)
                 (mutbl : Bool) (name : Ident)
                 (ty : Ty) (val : Option Expr) (eii : List EiiImpl)
    -- Use & extern
    | use_       (attrs : List Attribute) (vis : Option Visibility) (tree : UseTree)
    | externCrate (attrs : List Attribute) (vis : Option Visibility)
                  (name : Ident) (alias : Option Ident)
    -- Attributes & macros
    | attribute  (inner : Bool) (attr : Attribute)
    | macro_     (inv : MacroInvocation)
    | macroDef   (name : Ident) (rules : List MacroRule)
    -- Assembly & delegation
    | globalAsm    (asm : InlineAsm)
    | delegation   (attrs : List Attribute) (vis : Option Visibility)
                   (id : Ident) (target : ScopedPath) (rename : Option Ident)
                   (body : Option Block)
    | delegationMac (attrs : List Attribute) (target : ScopedPath)
                    (suffixes : List Ident) (body : Option Block)

  /-- A trait implementation reference (`impl Trait for T` vs `impl !Trait for T`). -/
  inductive ImplTrait
    | positive (ty : Ty)
    | negative (ty : Ty)

  /-- Items that can appear inside a `trait { … }` body. -/
  inductive TraitItem
    | fn_      (attrs : List Attribute) (vis : Option Visibility)
               (mods : FnModifiers) (name : Ident)
               (typeParams : Option TypeParams) (params : List Param)
               (ret : Option Ty) (where_ : Option (List WherePred))
               (body : Option Block)
    | assocType (attrs : List Attribute) (name : Ident)
                (typeParams : Option TypeParams) (bounds : Option TraitBound)
                (where_ : Option (List WherePred)) (default_ : Option Ty)
    | const_   (attrs : List Attribute) (name : Ident) (ty : Ty) (default_ : Option Expr)
    | macro_   (inv : MacroInvocation)

  /-- Items that can appear inside an `impl { … }` body. -/
  inductive ImplItem
    | fn_      (attrs : List Attribute) (vis : Option Visibility)
               (mods : FnModifiers) (name : Ident)
               (typeParams : Option TypeParams) (params : List Param)
               (ret : Option Ty) (where_ : Option (List WherePred))
               (body : Block)
    | assocType (attrs : List Attribute) (vis : Option Visibility)
                (name : Ident) (typeParams : Option TypeParams)
                (bounds : Option TraitBound)
                (where_ : Option (List WherePred)) (ty : Ty)
    | const_   (attrs : List Attribute) (vis : Option Visibility)
               (name : Ident) (ty : Ty) (val : Expr)
    | macro_   (inv : MacroInvocation)

  /-- Items that can appear inside `extern { … }` blocks. -/
  inductive ForeignItem
    | fn_    (attrs : List Attribute) (vis : Option Visibility)
             (name : Ident) (typeParams : Option TypeParams)
             (params : List Param) (ret : Option Ty)
             (where_ : Option (List WherePred))
    | static_ (attrs : List Attribute) (vis : Option Visibility)
              (mutbl : Bool) (name : Ident) (ty : Ty)
    | type_   (attrs : List Attribute) (vis : Option Visibility) (name : Ident)
    | macro_  (inv : MacroInvocation)

  /-- Struct or enum-variant body. -/
  inductive StructBody
    | unit
    | tuple  (fields : List TupleField)
    | record (fields : List FieldDecl)

  inductive TupleField
    | mk (attrs : List Attribute) (vis : Option Visibility) (ty : Ty)

  inductive FieldDecl
    | mk (attrs : List Attribute) (vis : Option Visibility) (name : Ident) (ty : Ty)

  inductive EnumVariant
    | mk (attrs : List Attribute) (vis : Option Visibility)
         (name : Ident) (body : StructBody) (disc : Option Expr)

  /-- An attribute `#[…]` or `#![…]`. -/
  inductive Attribute
    | normal     (inner : Bool) (path : ScopedPath) (value : Option AttrValue)
    | docComment (inner : Bool) (content : String)

  inductive AttrValue
    | eq    (e : Expr)
    | args  (tt : TokenTree)

end  -- mutual
