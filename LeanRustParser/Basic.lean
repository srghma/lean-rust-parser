module

@[expose] public section

-- Rust/Basic.lean
-- A complete Lean 4 AST for Rust, derived from rustc_ast and the syn crate,
-- covering all stable and nightly constructs.
-- This file contains only data type definitions (no pretty-printing, no elaboration).

/-! ──────────────────────────────────────────────────────────────
    § 1  Primitive leaf types
──────────────────────────────────────────────────────────────── -/

/-- Rust primitive scalar types (including f16/f128 nightly types). -/
inductive PrimitiveType
  | u8 | i8 | u16 | i16 | u32 | i32 | u64 | i64
  | u128 | i128 | isize | usize | f16 | f32 | f64 | f128
  | bool_ | str_ | char_
  deriving Repr, DecidableEq

def PrimitiveType.toString : PrimitiveType → String
  | .u8    => "u8"    | .i8    => "i8"
  | .u16   => "u16"   | .i16   => "i16"
  | .u32   => "u32"   | .i32   => "i32"
  | .u64   => "u64"   | .i64   => "i64"
  | .u128  => "u128"  | .i128  => "i128"
  | .isize => "isize" | .usize => "usize"
  | .f16   => "f16"   | .f32   => "f32"
  | .f64   => "f64"   | .f128  => "f128"
  | .bool_ => "bool"  | .str_  => "str"  | .char_ => "char"

/-- An identifier (possibly raw `r#foo`). -/
structure Ident where
  name : String
  deriving Repr, DecidableEq, Inhabited

instance : ToString Ident := ⟨(·.name)⟩

/-- A lifetime `'a`. -/
structure Lifetime where
  name : String   -- without the leading `'`
  deriving Repr, DecidableEq

def Lifetime.toString (l : Lifetime) : String := "'" ++ l.name

/-- A label `'outer`. -/
structure Label where
  name : String
  deriving Repr, DecidableEq

def Label.toString (l : Label) : String := "'" ++ l.name

/-- Fragment specifiers inside macro_rules patterns. -/
inductive FragmentSpecifier
  | block | expr | expr2021 | ident | item | lifetime | literal
  | meta_ | pat | patParam | path | stmt | tt | ty | vis
  deriving Repr, DecidableEq

def FragmentSpecifier.toString : FragmentSpecifier → String
  | .block    => "block"    | .expr     => "expr"
  | .expr2021 => "expr_2021"| .ident    => "ident"
  | .item     => "item"     | .lifetime => "lifetime"
  | .literal  => "literal"  | .meta_    => "meta"
  | .pat      => "pat"      | .patParam => "pat_param"
  | .path     => "path"     | .stmt     => "stmt"
  | .tt       => "tt"       | .ty       => "ty"
  | .vis      => "vis"

/-- Visibility modifier (matches rustc's `VisibilityKind`). -/
inductive Visibility
  | inherited            -- default (no modifier)
  | pub                  -- `pub`
  | pubCrate             -- `pub(crate)`
  | pubSelf              -- `pub(self)`
  | pubSuper             -- `pub(super)`
  | pubIn (path : String) -- `pub(in path)`
  | crateKw              -- bare `crate` (old-style)
  deriving Repr, DecidableEq

def Visibility.toString : Visibility → String
  | .inherited  => ""
  | .pub        => "pub"
  | .pubCrate   => "pub(crate)"
  | .pubSelf    => "pub(self)"
  | .pubSuper   => "pub(super)"
  | .pubIn p    => s!"pub(in {p})"
  | .crateKw    => "crate"

/-- Binary operators (arithmetic, logical, bitwise, comparison). -/
inductive BinOp
  | and | or | bitAnd | bitOr | bitXor
  | eq | ne | lt | le | gt | ge
  | shl | shr | add | sub | mul | div | rem
  deriving Repr, DecidableEq

def BinOp.toString : BinOp → String
  | .and    => "&&" | .or     => "||"
  | .bitAnd => "&"  | .bitOr  => "|"  | .bitXor => "^"
  | .eq     => "==" | .ne     => "!=" | .lt     => "<"  | .le => "<="
  | .gt     => ">"  | .ge     => ">="
  | .shl    => "<<" | .shr    => ">>"
  | .add    => "+"  | .sub    => "-"  | .mul    => "*"
  | .div    => "/"  | .rem    => "%"

/-- Compound-assignment operators. -/
inductive CompoundOp
  | addEq | subEq | mulEq | divEq | remEq
  | andEq | orEq  | xorEq | shlEq | shrEq
  deriving Repr, DecidableEq

def CompoundOp.toString : CompoundOp → String
  | .addEq => "+=" | .subEq => "-=" | .mulEq => "*="
  | .divEq => "/=" | .remEq => "%=" | .andEq => "&="
  | .orEq  => "|=" | .xorEq => "^=" | .shlEq => "<<=" | .shrEq => ">>="

/-- Unary operators. -/
inductive UnaryOp | neg | deref | not deriving Repr, DecidableEq

def UnaryOp.toString : UnaryOp → String
  | .neg => "-" | .deref => "*" | .not => "!"

/-- Range operators. -/
inductive RangeOp | exclusive | inclusive | dotDotDot deriving Repr, DecidableEq

def RangeOp.toString : RangeOp → String
  | .exclusive => ".." | .inclusive => "..=" | .dotDotDot => "..."

/-- How a closure captures its environment (rustc `CaptureBy`). -/
inductive CaptureBy
  | value   -- `move`
  | ref_    -- default (by reference)
  | use_    -- `use` (precise capturing, nightly)
  deriving Repr, DecidableEq

/-- The kind of generator block (rustc `GenBlockKind`). -/
inductive GenBlockKind
  | async_    -- `async { ... }`
  | gen       -- `gen { ... }` (nightly)
  | asyncGen  -- `async gen { ... }` (nightly)
  deriving Repr, DecidableEq

/-- Whether a `match` is prefix or postfix (nightly postfix-match). -/
inductive MatchKind | prefix | postfix deriving Repr, DecidableEq

/-- Whether a `yield` is prefix or postfix. -/
inductive YieldKind | prefix | postfix deriving Repr, DecidableEq

/-- Whether a `for` loop is plain or `for await`. -/
inductive ForLoopKind | for_ | forAwait deriving Repr, DecidableEq

/-- Unsafe binder cast direction. -/
inductive UnsafeBinderCastKind | wrap | unwrap deriving Repr, DecidableEq

/-- How a macro invocation statement is terminated. -/
inductive MacStmtStyle
  | semicolon  -- `mac!(...);`
  | braces     -- `mac! { ... }` (no semicolon needed)
  | noBraces   -- `mac!(...)` used as expression statement
  deriving Repr, DecidableEq

/-- TraitBound modifier (e.g. `?Sized`). -/
inductive TraitBoundModifier | none | maybe | maybeConst deriving Repr, DecidableEq


/-- Literal values. -/
inductive Literal
  | int_    (raw : String)
  | float_  (raw : String)
  | str_    (raw : String)       -- `"hello"`
  | byteStr (raw : String)       -- `b"hello"`
  | cStr    (raw : String)       -- `c"hello"` (C-string literal)
  | rawStr  (raw : String)       -- `r#"..."#`
  | char_   (raw : String)       -- `'a'`
  | byte_   (raw : String)       -- `b'x'`
  | bool_   (b : Bool)
  deriving Repr

-- 1. Standalone types extracted from the mutual block
-- These do not depend on the core cycle (Expr/Ty/Stmt/Item).


/-- Function modifier flags (safety, constness, asyncness, extern ABI). -/
inductive FnModifiers
  | mods (coroutine : Option GenBlockKind)
         (isConst : Bool)
         (isUnsafe : Bool)
         (isDefault : Bool)
         (extABI : Option (Option String))  -- None = no extern; some none = bare extern; some (some "C") = extern "C"
  deriving Repr

/-- Token tree (opaque, stored as raw string per delimiter kind). -/
inductive TokenTree
  | parens   (content : String)
  | brackets (content : String)
  | braces   (content : String)
  deriving Repr
/-- A macro_rules rule: `pattern => body`. -/
inductive MacroRule
  | mk (pattern : TokenTree) (body : TokenTree)
  deriving Repr
/-- Use tree (import path). -/
inductive UseTree
  | path  (seg : Ident) (child : UseTree)
  | name  (id : Ident)
  | alias (id : Ident) (alias : Ident)
  | glob
  | list  (trees : List UseTree)
  | self_
  deriving Repr

/-! ──────────────────────────────────────────────────────────────
    § 2  Mutually recursive AST
        (Literal, ScopedPath, Ty, TraitBound, TypeArgs,
         Block, Expr, Pat, Stmt, Item, …)
──────────────────────────────────────────────────────────────── -/

-- We vastly increase heartbeats because deriving `Repr` for 40+ highly mutually
-- recursive inductive types requires immense traversal limits in Lean 4's typeclass synthesis.
set_option maxHeartbeats 2000000


/-! ──────────────────────────────────────────────────────────────
    § 2  Mutually recursive AST
        (Literal, ScopedPath, Ty, TraitBound, TypeArgs,
         Block, Expr, Pat, Stmt, Item, …)
──────────────────────────────────────────────────────────────── -/


/-!

```mermaid
flowchart TD
    %% Base & Paths
    ScopedPath --> ScopedPath
    ScopedPath --> Ty
    ScopedPath --> TypeArgs

    MacroInvocation --> ScopedPath

    %% Type Arguments & Parameters
    TypeArgs --> TypeArgItem

    TypeArgItem --> Ty
    TypeArgItem --> Expr
    TypeArgItem --> TraitBound
    TypeArgItem --> Block

    TypeParams --> TypeParamItem

    TypeParamItem --> Ty
    TypeParamItem --> TraitBound
    TypeParamItem --> ConstParamDefault

    ConstParamDefault --> Block

    %% Types
    Ty --> Ty
    Ty --> ScopedPath
    Ty --> TypeArgs
    Ty --> BareFnArg
    Ty --> TraitBoundItem
    Ty --> TypeParams
    Ty --> Pat
    Ty --> MacroInvocation

    BareFnArg --> Ty

    %% Traits & Bounds
    TraitBound --> TraitBoundItem

    TraitBoundItem --> Ty
    TraitBoundItem --> PreciseCapturingArg

    PreciseCapturingArg --> ScopedPath

    WherePred --> Ty
    WherePred --> TraitBound

    ImplTrait --> Ty

    %% Blocks & Statements
    Block --> Stmt
    Block --> Expr

    Stmt --> Expr
    Stmt --> Pat
    Stmt --> Ty
    Stmt --> Block
    Stmt --> Item
    Stmt --> MacroInvocation

    %% Patterns
    Pat --> Pat
    Pat --> ScopedPath
    Pat --> FieldPat
    Pat --> RangePat
    Pat --> Block
    Pat --> Expr
    Pat --> MacroInvocation

    RangePat --> ScopedPath
    FieldPat --> Pat

    %% Expressions
    Expr --> Expr
    Expr --> ScopedPath
    Expr --> Ty
    Expr --> TypeArgs
    Expr --> ClosureParam
    Expr --> ClosureBody
    Expr --> Block
    Expr --> Condition
    Expr --> ElseClause
    Expr --> MatchArm
    Expr --> Pat
    Expr --> ArrayExprKind
    Expr --> StructExprName
    Expr --> FieldInit
    Expr --> MacroInvocation
    Expr --> InlineAsm

    ArrayExprKind --> Expr
    ClosureParam --> Pat
    ClosureParam --> Ty
    ClosureBody --> Expr
    ClosureBody --> Block

    Condition --> Expr
    Condition --> Pat
    Condition --> LetChainItem

    LetChainItem --> Expr
    LetChainItem --> Pat

    ElseClause --> Block
    ElseClause --> Expr

    MatchArm --> Attribute
    MatchArm --> Pat
    MatchArm --> Condition
    MatchArm --> Expr

    StructExprName --> ScopedPath
    StructExprName --> TypeArgs
    StructExprName --> Ty

    FieldInit --> Expr

    %% Inline Assembly
    InlineAsm --> InlineAsmOperand
    InlineAsmOperand --> Expr
    InlineAsmOperand --> ScopedPath
    InlineAsmOperand --> Block

    %% Items
    Item --> Item
    Item --> Attribute
    Item --> ForeignItem
    Item --> TypeParams
    Item --> WherePred
    Item --> StructBody
    Item --> FieldDecl
    Item --> EnumVariant
    Item --> Ty
    Item --> TraitBound
    Item --> Param
    Item --> Block
    Item --> FnContract
    Item --> EiiImpl
    Item --> TraitItem
    Item --> ImplTrait
    Item --> ImplItem
    Item --> Expr
    Item --> MacroInvocation
    Item --> ScopedPath

    TraitItem --> Attribute
    TraitItem --> TypeParams
    TraitItem --> Param
    TraitItem --> Ty
    TraitItem --> WherePred
    TraitItem --> Block
    TraitItem --> TraitBound
    TraitItem --> Expr
    TraitItem --> MacroInvocation

    ImplItem --> Attribute
    ImplItem --> TypeParams
    ImplItem --> Param
    ImplItem --> Ty
    ImplItem --> WherePred
    ImplItem --> Block
    ImplItem --> TraitBound
    ImplItem --> Expr
    ImplItem --> MacroInvocation

    ForeignItem --> Attribute
    ForeignItem --> TypeParams
    ForeignItem --> Param
    ForeignItem --> Ty
    ForeignItem --> WherePred
    ForeignItem --> MacroInvocation

    %% Structs, Enums, & Fields
    StructBody --> TupleField
    StructBody --> FieldDecl

    TupleField --> Attribute
    TupleField --> Ty

    FieldDecl --> Attribute
    FieldDecl --> Ty

    EnumVariant --> Attribute
    EnumVariant --> StructBody
    EnumVariant --> Expr

    %% Attributes & Contracts
    Attribute --> ScopedPath
    Attribute --> AttrValue
    AttrValue --> Expr

    FnContract --> Stmt
    FnContract --> Expr

    EiiImpl --> ScopedPath

    Param --> Pat
    Param --> Ty
```
-/

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
    deriving Repr

  /-- Type arguments `<A, B, 'a, const N, Item = T>`. -/
  inductive TypeArgs
    | args (items : List TypeArgItem)
    deriving Repr

  inductive TypeArgItem
    | ty         (t : Ty)
    | lifetime   (l : Lifetime)
    | binding    (name : Ident) (t : Ty)      -- `Item = T`
    | assocConst (name : Ident) (val : Expr)  -- `PANIC = false`
    | constraint (name : Ident) (bounds : TraitBound) -- `Item: Display`
    | literal    (lit : Literal)
    | block      (b : Block)
    | infer                                   -- `_`
    deriving Repr

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
    deriving Repr

  /-- A bare function argument `name: Ty` in a `fn(…)` type. -/
  inductive BareFnArg
    | named    (name : Option Ident) (ty : Ty)
    | variadic (name : Option Ident)           -- `...`
    deriving Repr

  /-- A trait bound: the items after `:` in `T: Trait + 'a + use<'b>`. -/
  inductive TraitBound
    | bounds (items : List TraitBoundItem)
    deriving Repr

  inductive TraitBoundItem
    | trait_       (modifier : TraitBoundModifier) (forLts : List Lifetime) (t : Ty)
    | lifetime     (l : Lifetime)
    | use_         (args : List PreciseCapturingArg)  -- `use<'a, T>` precise capturing
    deriving Repr

  /-- Arguments in a `use<…>` precise-capturing bound. -/
  inductive PreciseCapturingArg
    | lifetime (l : Lifetime)
    | arg      (p : ScopedPath)
    deriving Repr

  /-- A braced block `{ stmt* expr? }`. -/
  inductive Block
    | mk (label : Option Label) (stmts : List Stmt) (tail : Option Expr)
    deriving Repr


  /-- A where-clause predicate. -/
  inductive WherePred
    | ty       (lhs : Ty) (bounds : TraitBound)
    | lifetime (lt : Lifetime) (bounds : List Lifetime)
    deriving Repr

  /-- Generic parameters `<T: Trait, 'a, const N: usize>`. -/
  inductive TypeParams
    | params (items : List TypeParamItem)
    deriving Repr

  inductive TypeParamItem
    | ty       (name : Ident) (bounds : Option TraitBound) (default_ : Option Ty)
    | lifetime (lt : Lifetime) (bounds : Option TraitBound)
    | const_   (name : Ident) (ty : Ty) (default_ : Option ConstParamDefault)
    | metavar  (name : String)
    deriving Repr

  inductive ConstParamDefault
    | block   (b : Block)
    | ident   (id : Ident)
    | literal (l : Literal)
    deriving Repr

  /-- A function parameter. -/
  inductive Param
    | named    (mutbl : Bool) (pat : Pat) (ty : Ty)
    | self_    (byRef : Bool) (lt : Option Lifetime) (mutbl : Bool)
    | variadic (pat : Option Pat)
    | anon     (ty : Ty)
    deriving Repr

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
    deriving Repr

  inductive RangePat
    | literal (l : Literal)
    | path    (p : ScopedPath)
    deriving Repr

  inductive FieldPat
    | shorthand (byRef mutbl : Bool) (name : Ident)
    | full      (byRef mutbl : Bool) (name : Ident) (pat : Pat)
    | remaining
    deriving Repr

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
    | closure    (isStatic : Bool) (capture : CaptureBy) (params : List ClosureParam)
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
    deriving Repr

  inductive ArrayExprKind
    | list   (elems : List Expr)
    | repeat (elem : Expr) (len : Expr)
    deriving Repr

  inductive ClosureParam
    | pat   (p : Pat)
    | typed (p : Pat) (ty : Ty)
    deriving Repr

  inductive ClosureBody
    | expr  (e : Expr)
    | block (b : Block)
    | hole             -- `_`
    deriving Repr

  inductive Condition
    | expr    (e : Expr)
    | let_    (pat : Pat) (val : Expr)
    | letChain (items : List LetChainItem)
    deriving Repr

  inductive LetChainItem
    | expr (e : Expr)
    | let_ (pat : Pat) (val : Expr)
    deriving Repr

  inductive ElseClause
    | block  (b : Block)
    | elseIf (e : Expr)
    deriving Repr

  inductive MatchArm
    | mk (attrs : List Attribute) (pat : Pat) (guard : Option Condition) (val : Expr)
    deriving Repr

  inductive StructExprName
    | named      (id : Ident)
    | scoped     (sp : ScopedPath) (name : Ident)
    | turbofish  (id : Ident) (args : TypeArgs)
    | qpath      (qself : Ty) (trait_ : Option ScopedPath) (seg : Ident)
    deriving Repr

  inductive FieldInit
    | shorthand (id : Ident)
    | full      (field : Ident) (val : Expr)
    deriving Repr

  /-- A statement. Mirrors rustc's `StmtKind` exactly. -/
  inductive Stmt
    | expr    (e : Expr)                       -- expression without trailing `;`
    | semi    (e : Expr)                       -- expression with trailing `;`
    | let_    (mutbl : Bool) (pat : Pat) (ty : Option Ty)
              (init : Option Expr) (else_ : Option Block)
    | item    (it : Item)
    | macCall (mac : MacroInvocation) (style : MacStmtStyle)
    | empty
    deriving Repr

  /-- A macro invocation `path!(tokens)`. -/
  inductive MacroInvocation
    | mk (path : ScopedPath) (tokens : TokenTree)
    deriving Repr

  /-- Externally implementable items mappings. -/
  inductive EiiImpl
    | mk (path : ScopedPath) (isDefault : Bool)
    deriving Repr

  /-- Contract logic for function definitions. -/
  inductive FnContract
    | mk (decls : List Stmt) (requires : Option Expr) (ensures : Option Expr)
    deriving Repr

  /-- Minimal subset of Inline Assembly operands. -/
  inductive InlineAsmOperand
    | in_        (reg : String) (expr : Expr)
    | out        (reg : String) (expr : Option Expr)
    | inOut      (reg : String) (expr : Expr)
    | splitInOut (reg : String) (inExpr : Expr) (outExpr : Option Expr)
    | const_     (expr : Expr)
    | sym_       (path : ScopedPath)
    | label_     (block : Block)
    deriving Repr

  /-- Inline assembly expression. -/
  inductive InlineAsm
    | mk (template : List String) (operands : List InlineAsmOperand)
    deriving Repr

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
    deriving Repr

  /-- A trait implementation reference (`impl Trait for T` vs `impl !Trait for T`). -/
  inductive ImplTrait
    | positive (ty : Ty)
    | negative (ty : Ty)
    deriving Repr

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
    deriving Repr

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
    deriving Repr

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
    deriving Repr

  /-- Struct or enum-variant body. -/
  inductive StructBody
    | unit
    | tuple  (fields : List TupleField)
    | record (fields : List FieldDecl)
    deriving Repr

  inductive TupleField
    | mk (attrs : List Attribute) (vis : Option Visibility) (ty : Ty)
    deriving Repr

  inductive FieldDecl
    | mk (attrs : List Attribute) (vis : Option Visibility) (name : Ident) (ty : Ty)
    deriving Repr

  inductive EnumVariant
    | mk (attrs : List Attribute) (vis : Option Visibility)
         (name : Ident) (body : StructBody) (disc : Option Expr)
    deriving Repr

  /-- An attribute `#[…]` or `#![…]`. -/
  inductive Attribute
    | normal     (inner : Bool) (path : ScopedPath) (value : Option AttrValue)
    | docComment (inner : Bool) (content : String)
    deriving Repr

  inductive AttrValue
    | eq    (e : Expr)
    | args  (tt : TokenTree)
    deriving Repr

end  -- mutual

/-! ──────────────────────────────────────────────────────────────
    § 3  Derived helpers
──────────────────────────────────────────────────────────────── -/

def FnModifiers.none : FnModifiers :=
  .mods Option.none false false false Option.none

/-- A complete Rust source file. -/
structure SourceFile where
  shebang : Option String
  attrs   : List Attribute
  items   : List Item
  deriving Repr
