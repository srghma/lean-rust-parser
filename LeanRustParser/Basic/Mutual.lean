module

public import LeanRustParser.Basic.NonMutual

@[expose] public section

inductive TypeArgsCore.{u} (Item : Type u)
  | args (items : List Item)

inductive TypeArgItemCore.{u} (Ty Expr Block TraitBound : Type u)
  | ty         (t : Ty)
  | lifetime   (l : Lifetime)
  | binding    (name : Ident) (t : Ty)
  | assocConst (name : Ident) (val : Expr)
  | constraint (name : Ident) (bounds : TraitBound)
  | literal    (lit : Literal)
  | block      (b : Block)
  | infer

inductive TraitBoundCore.{u} (Item : Type u)
  | bounds (items : List Item)

inductive PreciseCapturingArgCore.{u} (ScopedPath : Type u)
  | lifetime (l : Lifetime)
  | arg      (p : ScopedPath)

inductive TraitBoundItemCore.{u} (Ty PreciseCapturingArg : Type u)
  | trait_       (modifier : TraitBoundModifier) (forLts : List Lifetime) (t : Ty)
  | lifetime     (l : Lifetime)
  | use_         (args : List PreciseCapturingArg)

inductive TypeParamsCore.{u} (Item : Type u)
  | params (items : List Item)

inductive TypeParamItemCore.{u} (Ty TraitBound ConstParamDefault : Type u)
  | ty       (name : Ident) (bounds : Option TraitBound) (default_ : Option Ty)
  | lifetime (lt : Lifetime) (bounds : Option TraitBound)
  | const_   (name : Ident) (ty : Ty) (default_ : Option ConstParamDefault)
  | metavar  (name : String)

inductive ConstParamDefaultCore.{u} (Block : Type u)
  | block   (b : Block)
  | ident   (id : Ident)
  | literal (l : Literal)

inductive BlockCore.{u} (Stmt Expr : Type u)
  | mk (label : Option Label) (stmts : List Stmt) (tail : Option Expr)

inductive BareFnArgCore.{u} (Ty : Type u)
  | named    (name : Option Ident) (ty : Ty)
  | variadic (name : Option Ident)

inductive WherePredCore.{u} (Ty TraitBound : Type u)
  | ty       (lhs : Ty) (bounds : TraitBound)
  | lifetime (lt : Lifetime) (bounds : List Lifetime)

inductive ParamCore.{u} (Pat Ty : Type u)
  | named    (mutbl : Bool) (pat : Pat) (ty : Ty)
  | self_    (byRef : Bool) (lt : Option Lifetime) (mutbl : Bool)
  | variadic (pat : Option Pat)
  | anon     (ty : Ty)

inductive RangePatCore.{u} (ScopedPath : Type u)
  | literal (l : Literal)
  | path    (p : ScopedPath)

inductive FieldPatCore.{u} (Pat : Type u)
  | shorthand (byRef mutbl : Bool) (name : Ident)
  | full      (byRef mutbl : Bool) (name : Ident) (pat : Pat)
  | remaining

inductive ClosureParamCore.{u} (Pat Ty : Type u)
  | pat   (p : Pat)
  | typed (p : Pat) (ty : Ty)

inductive ClosureBodyCore.{u} (Expr Block : Type u)
  | expr  (e : Expr)
  | block (b : Block)
  | hole

inductive LetChainItemCore.{u} (Pat Expr : Type u)
  | expr (e : Expr)
  | let_ (pat : Pat) (val : Expr)

inductive ConditionCore.{u} (LetChainItem Pat Expr : Type u)
  | expr    (e : Expr)
  | let_    (pat : Pat) (val : Expr)
  | letChain (items : List LetChainItem)

inductive ElseClauseCore.{u} (Block Expr : Type u)
  | block  (b : Block)
  | elseIf (e : Expr)

inductive MatchArmCore.{u} (Attribute Pat Condition Expr : Type u)
  | mk (attrs : List Attribute) (pat : Pat) (guard : Option Condition) (val : Expr)

inductive FieldInitCore.{u} (Expr : Type u)
  | shorthand (id : Ident)
  | full      (field : Ident) (val : Expr)

inductive MacroInvocationCore.{u} (ScopedPath : Type u)
  | mk (path : ScopedPath) (tokens : TokenTree)

inductive EiiImplCore.{u} (ScopedPath : Type u)
  | mk (path : ScopedPath) (isDefault : Bool)

inductive FnContractCore.{u} (Stmt Expr : Type u)
  | mk (decls : List Stmt) (requires : Option Expr) (ensures : Option Expr)

inductive InlineAsmOperandCore.{u} (Expr ScopedPath Block : Type u)
  | in_        (reg : String) (expr : Expr)
  | out        (reg : String) (expr : Option Expr)
  | inOut      (reg : String) (expr : Expr)
  | splitInOut (reg : String) (inExpr : Expr) (outExpr : Option Expr)
  | const_     (expr : Expr)
  | sym_       (path : ScopedPath)
  | label_     (block : Block)

inductive InlineAsmCore.{u} (InlineAsmOperand : Type u)
  | mk (template : List String) (operands : List InlineAsmOperand)

/-! ──────────────────────────────────────────────────────────────
    § 2  Smaller mutual core
──────────────────────────────────────────────────────────────── -/

set_option maxHeartbeats 20000000

mutual
  inductive ScopedPath
    | self_
    | super_
    | crate_
    | ident      (id : Ident)
    | scoped     (head : ScopedPath) (seg : Ident)
    | generic    (head : ScopedPath) (args : TypeArgsCore (TypeArgItemCore Ty Expr (BlockCore Stmt Expr) (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))
    | bracketed  (inner : Ty)
    | qpath      (qself : Ty) (trait_ : Option ScopedPath) (seg : Ident)

  inductive Ty
    | primitive    (p : PrimitiveType)
    | named        (id : Ident)
    | scoped       (path : Option ScopedPath) (name : Ident)
    | path         (sp : ScopedPath)
    | generic      (ty : Ty) (args : TypeArgsCore (TypeArgItemCore Ty Expr (BlockCore Stmt Expr) (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))
    | reference    (lt : Option Lifetime) (mutbl : Bool) (inner : Ty)
    | pinnedRef    (lt : Option Lifetime) (mutbl : Bool) (inner : Ty)
    | pointer      (isConst : Bool) (inner : Ty)
    | array        (elem : Ty) (len : Option Expr)
    | slice        (elem : Ty)
    | tuple        (elems : List Ty)
    | unit
    | never
    | infer
    | paren        (inner : Ty)
    | fn_          (mods : FnModifiers) (params : List (BareFnArgCore Ty)) (ret : Option Ty)
    | implTrait    (bounds : List (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))
    | dynTrait     (bounds : List (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))
    | unsafeBinder (params : TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))) (inner : Ty)
    | pat          (ty : Ty) (pat : Pat)
    | fieldOf      (ty : Ty) (enum_var : Option Ident) (field : Ident)
    | cVarArgs
    | implicitSelf
    | metavar      (name : String)
    | macro_       (inv : MacroInvocationCore ScopedPath)
    | group        (inner : Ty)
    | dummy
    | err

  inductive Pat
    | literal    (lit : Literal)
    | ident      (byRef mutbl : Bool) (id : Ident) (bound : Option Pat)
    | primitive  (p : PrimitiveType)
    | path       (sp : ScopedPath)
    | tuple      (pats : List Pat)
    | tupleStruct (ty : ScopedPath) (pats : List Pat)
    | struct_    (ty : ScopedPath) (fields : List (FieldPatCore Pat)) (rest : Bool)
    | slice      (pats : List Pat)
    | reference  (mutbl : Bool) (inner : Pat)
    | range      (lo : Option (RangePatCore ScopedPath)) (op : RangeOp) (hi : Option (RangePatCore ScopedPath))
    | or         (alts : List Pat)
    | box_       (inner : Pat)
    | deref      (inner : Pat)
    | never
    | paren      (inner : Pat)
    | guard      (pat : Pat) (cond : Expr)
    | rest
    | wildcard
    | constBlock (b : BlockCore Stmt Expr)
    | macro_     (inv : MacroInvocationCore ScopedPath)
    | err

  inductive Expr
    | literal    (l : Literal)
    | ident      (id : Ident)
    | primitive  (p : PrimitiveType)
    | self_
    | path       (sp : ScopedPath)
    | metavar    (name : String)
    | infer
    | unary      (op : UnaryOp) (e : Expr)
    | binary     (op : BinOp) (l r : Expr)
    | assign     (l r : Expr)
    | compoundAssign (op : CompoundOp) (l r : Expr)
    | cast       (e : Expr) (ty : Ty)
    | type_      (e : Expr) (ty : Ty)
    | try_       (e : Expr)
    | range      (lo : Option Expr) (op : RangeOp) (hi : Option Expr)
    | range_
    | call       (fn_ : Expr) (args : List Expr)
    | methodCall (recv : Expr) (method : Ident) (turbofish : Option (TypeArgsCore (TypeArgItemCore Ty Expr (BlockCore Stmt Expr) (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))) (args : List Expr)
    | field      (recv : Expr) (field : Ident)
    | tupleField (recv : Expr) (idx : Nat)
    | index      (recv : Expr) (idx : Expr)
    | await      (e : Expr)
    | move_      (e : Expr)
    | become     (e : Expr)
    | yeet       (e : Option Expr)
    | closure    (isAsync : Bool) (capture : CaptureBy) (params : List (ClosureParamCore Pat Ty))
                 (ret : Option Ty) (body : ClosureBodyCore Expr (BlockCore Stmt Expr))
    | block      (b : BlockCore Stmt Expr)
    | unsafeBlock (b : BlockCore Stmt Expr)
    | genBlock   (capture : CaptureBy) (b : BlockCore Stmt Expr) (kind : GenBlockKind)
    | tryBlock   (b : BlockCore Stmt Expr) (ty : Option Ty)
    | constBlock (b : BlockCore Stmt Expr)
    | if_        (cond : ConditionCore (LetChainItemCore Pat Expr) Pat Expr) (then_ : BlockCore Stmt Expr) (else_ : Option (ElseClauseCore (BlockCore Stmt Expr) Expr))
    | match_     (val : Expr) (arms : List (MatchArmCore Attribute Pat (ConditionCore (LetChainItemCore Pat Expr) Pat Expr) Expr)) (kind : MatchKind)
    | while_     (label : Option Label) (cond : ConditionCore (LetChainItemCore Pat Expr) Pat Expr) (body : BlockCore Stmt Expr)
    | loop_      (label : Option Label) (body : BlockCore Stmt Expr)
    | for_       (label : Option Label) (pat : Pat) (iter : Expr) (body : BlockCore Stmt Expr)
                 (kind : ForLoopKind)
    | return_    (val : Option Expr)
    | yield_     (val : Option Expr) (kind : YieldKind)
    | break_     (label : Option Label) (val : Option Expr)
    | continue_  (label : Option Label)
    | use_       (e : Expr)
    | array      (elems : ArrayExprKind)
    | tuple      (elems : List Expr)
    | unit
    | struct_    (name : StructExprName) (fields : List (FieldInitCore Expr)) (base : Option Expr)
    | paren      (e : Expr)
    | genericFn  (fn_ : Expr) (args : TypeArgsCore (TypeArgItemCore Ty Expr (BlockCore Stmt Expr) (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))
    | macro_     (inv : MacroInvocationCore ScopedPath)
    | formatArgs (tt : TokenTree)
    | inlineAsm  (asm : InlineAsmCore (InlineAsmOperandCore Expr ScopedPath (BlockCore Stmt Expr)))
    | offsetOf   (ty : Ty) (fields : List Ident)
    | includedBytes (path : String)
    | reference  (raw : Bool) (mutbl : Bool) (e : Expr)
    | unsafeBinderCast (kind : UnsafeBinderCastKind) (e : Expr) (ty : Option Ty)
    | dummy
    | err

  inductive ArrayExprKind
    | list   (elems : List Expr)
    | repeat (elem : Expr) (len : Expr)

  inductive StructExprName
    | named      (id : Ident)
    | scoped     (sp : ScopedPath) (name : Ident)
    | turbofish  (id : Ident) (args : TypeArgsCore (TypeArgItemCore Ty Expr (BlockCore Stmt Expr) (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))
    | qpath      (qself : Ty) (trait_ : Option ScopedPath) (seg : Ident)

  inductive Stmt
    | expr    (e : Expr)
    | semi    (e : Expr)
    | let_    (mutbl : Bool) (pat : Pat) (ty : Option Ty)
              (init : Option Expr) (else_ : Option (BlockCore Stmt Expr))
    | item    (it : Item)
    | macCall (mac : MacroInvocationCore ScopedPath) (style : MacStmtStyle)
    | empty

  inductive Item
    | mod        (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (body : Option (List Item))
    | foreignMod (attrs : List (Attribute)) (isUnsafe : Bool) (abi : Option String)
                 (items : List ForeignItem)
    | struct_    (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))) (body : StructBody)
    | union_     (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))) (fields : List FieldDecl)
    | enum_      (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))) (variants : List EnumVariant)
    | typeAlias  (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))) (ty : Option Ty)
    | traitAlias (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (bounds : TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))
    | fn_        (attrs : List Attribute) (vis : Option Visibility)
                 (mods : FnModifiers) (name : Ident)
                 (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (params : List (ParamCore Pat Ty))
                 (ret : Option Ty) (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))))
                 (body : Option (BlockCore Stmt Expr)) (contract : Option (FnContractCore Stmt Expr))
                 (eii : List (EiiImplCore ScopedPath))
    | fnSig      (attrs : List Attribute) (vis : Option Visibility)
                 (mods : FnModifiers) (name : Ident)
                 (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (params : List (ParamCore Pat Ty))
                 (ret : Option Ty) (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))))
                 (contract : Option (FnContractCore Stmt Expr))
    | trait_     (attrs : List Attribute) (vis : Option Visibility)
                 (isUnsafe : Bool) (name : Ident)
                 (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (bounds : Option (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))
                 (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))))
                 (items : List TraitItem)
    | impl_      (attrs : List Attribute) (isUnsafe : Bool)
                 (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr))))) (traitRef : Option ImplTrait)
                 (ty : Ty) (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))))
                 (items : List ImplItem)
    | assocType  (attrs : List Attribute) (name : Ident)
                 (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                 (bounds : Option (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))
                 (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))) (default_ : Option Ty)
    | const_     (attrs : List Attribute) (vis : Option Visibility)
                 (name : Ident) (ty : Ty) (val : Option Expr)
    | constBlock (b : BlockCore Stmt Expr)
    | static_    (attrs : List Attribute) (vis : Option Visibility)
                 (mutbl : Bool) (name : Ident)
                 (ty : Ty) (val : Option Expr) (eii : List (EiiImplCore ScopedPath))
    | use_       (attrs : List Attribute) (vis : Option Visibility) (tree : UseTree)
    | externCrate (attrs : List Attribute) (vis : Option Visibility)
                  (name : Ident) (alias : Option Ident)
    | attribute  (inner : Bool) (attr : Attribute)
    | macro_     (inv : MacroInvocationCore ScopedPath)
    | macroDef   (name : Ident) (rules : List MacroRule)
    | globalAsm    (asm : InlineAsmCore (InlineAsmOperandCore Expr ScopedPath (BlockCore Stmt Expr)))
    | delegation   (attrs : List Attribute) (vis : Option Visibility)
                   (id : Ident) (target : ScopedPath) (rename : Option Ident)
                   (body : Option (BlockCore Stmt Expr))
    | delegationMac (attrs : List Attribute) (target : ScopedPath)
                    (suffixes : List Ident) (body : Option (BlockCore Stmt Expr))

  inductive ImplTrait
    | positive (ty : Ty)
    | negative (ty : Ty)

  inductive ForeignItem
    | fn_    (attrs : List Attribute) (vis : Option Visibility)
             (name : Ident) (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
             (params : List (ParamCore Pat Ty)) (ret : Option Ty)
             (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))))
    | static_ (attrs : List Attribute) (vis : Option Visibility)
              (mutbl : Bool) (name : Ident) (ty : Ty)
    | type_   (attrs : List Attribute) (vis : Option Visibility) (name : Ident)
    | macro_  (inv : MacroInvocationCore ScopedPath)

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

  inductive Attribute
    | normal     (inner : Bool) (path : ScopedPath) (value : Option AttrValue)
    | docComment (inner : Bool) (content : String)

  inductive AttrValue
    | eq    (e : Expr)
    | args  (tt : TokenTree)

  inductive TraitItem
    | fn_      (attrs : List Attribute) (vis : Option Visibility)
               (mods : FnModifiers) (name : Ident)
               (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr))))) (params : List (ParamCore Pat Ty))
               (ret : Option Ty) (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))))
               (body : Option (BlockCore Stmt Expr))
    | assocType (attrs : List Attribute) (name : Ident)
                (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr))))) (bounds : Option (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))
                (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))) (default_ : Option Ty)
    | const_   (attrs : List Attribute) (name : Ident) (ty : Ty) (default_ : Option Expr)
    | macro_   (inv : MacroInvocationCore ScopedPath)

  inductive ImplItem
    | fn_      (attrs : List Attribute) (vis : Option Visibility)
               (mods : FnModifiers) (name : Ident)
               (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr))))) (params : List (ParamCore Pat Ty))
               (ret : Option Ty) (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))))
               (body : BlockCore Stmt Expr)
    | assocType (attrs : List Attribute) (vis : Option Visibility)
                (name : Ident) (typeParams : Option (TypeParamsCore (TypeParamItemCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))) (ConstParamDefaultCore (BlockCore Stmt Expr)))))
                (bounds : Option (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath))))
                (where_ : Option (List (WherePredCore Ty (TraitBoundCore (TraitBoundItemCore Ty (PreciseCapturingArgCore ScopedPath)))))) (ty : Ty)
    | const_   (attrs : List Attribute) (vis : Option Visibility)
               (name : Ident) (ty : Ty) (val : Expr)
    | macro_   (inv : MacroInvocationCore ScopedPath)

end

abbrev CoreBlock := BlockCore Stmt Expr
abbrev CorePreciseCapturingArg := PreciseCapturingArgCore ScopedPath
abbrev CoreTraitBoundItem := TraitBoundItemCore Ty CorePreciseCapturingArg
abbrev CoreTraitBound := TraitBoundCore CoreTraitBoundItem
abbrev CoreConstParamDefault := ConstParamDefaultCore CoreBlock
abbrev CoreTypeParamItem := TypeParamItemCore Ty CoreTraitBound CoreConstParamDefault
abbrev CoreTypeParams := TypeParamsCore CoreTypeParamItem
abbrev CoreTypeArgItem := TypeArgItemCore Ty Expr CoreBlock CoreTraitBound
abbrev CoreTypeArgs := TypeArgsCore CoreTypeArgItem
abbrev CoreWherePred := WherePredCore Ty CoreTraitBound
abbrev CoreParam := ParamCore Pat Ty
abbrev CoreRangePat := RangePatCore ScopedPath
abbrev CoreFieldPat := FieldPatCore Pat
abbrev CoreClosureParam := ClosureParamCore Pat Ty
abbrev CoreClosureBody := ClosureBodyCore Expr CoreBlock
abbrev CoreLetChainItem := LetChainItemCore Pat Expr
abbrev CoreCondition := ConditionCore CoreLetChainItem Pat Expr
abbrev CoreElseClause := ElseClauseCore CoreBlock Expr
abbrev CoreMatchArm := MatchArmCore Attribute Pat CoreCondition Expr
abbrev CoreFieldInit := FieldInitCore Expr
abbrev CoreMacroInvocation := MacroInvocationCore ScopedPath
abbrev CoreEiiImpl := EiiImplCore ScopedPath
abbrev CoreFnContract := FnContractCore Stmt Expr
abbrev CoreInlineAsmOperand := InlineAsmOperandCore Expr ScopedPath CoreBlock
abbrev CoreInlineAsm := InlineAsmCore CoreInlineAsmOperand

abbrev Block := CoreBlock
abbrev TypeArgs := CoreTypeArgs
abbrev TypeArgItem := CoreTypeArgItem
abbrev TraitBound := CoreTraitBound
abbrev TraitBoundItem := CoreTraitBoundItem
abbrev PreciseCapturingArg := CorePreciseCapturingArg
abbrev TypeParams := CoreTypeParams
abbrev TypeParamItem := CoreTypeParamItem
abbrev ConstParamDefault := CoreConstParamDefault
abbrev BareFnArg := BareFnArgCore Ty
abbrev WherePred := CoreWherePred
abbrev Param := CoreParam
abbrev RangePat := CoreRangePat
abbrev FieldPat := CoreFieldPat
abbrev ClosureParam := CoreClosureParam
abbrev ClosureBody := CoreClosureBody
abbrev LetChainItem := CoreLetChainItem
abbrev Condition := CoreCondition
abbrev ElseClause := CoreElseClause
abbrev MatchArm := CoreMatchArm
abbrev FieldInit := CoreFieldInit
abbrev MacroInvocation := CoreMacroInvocation
abbrev EiiImpl := CoreEiiImpl
abbrev FnContract := CoreFnContract
abbrev InlineAsmOperand := CoreInlineAsmOperand
abbrev InlineAsm := CoreInlineAsm

namespace Block
  export BlockCore (mk)
end Block

namespace TypeArgs
  export TypeArgsCore (args)
end TypeArgs

namespace TypeArgItem
  export TypeArgItemCore (ty lifetime binding assocConst constraint literal block infer)
end TypeArgItem

namespace TraitBound
  export TraitBoundCore (bounds)
end TraitBound

namespace TraitBoundItem
  export TraitBoundItemCore (trait_ lifetime use_)
end TraitBoundItem

namespace PreciseCapturingArg
  export PreciseCapturingArgCore (lifetime arg)
end PreciseCapturingArg

namespace TypeParams
  export TypeParamsCore (params)
end TypeParams

namespace TypeParamItem
  export TypeParamItemCore (ty lifetime const_ metavar)
end TypeParamItem

namespace ConstParamDefault
  export ConstParamDefaultCore (block ident literal)
end ConstParamDefault

namespace BareFnArg
  export BareFnArgCore (named variadic)
end BareFnArg

namespace WherePred
  export WherePredCore (ty lifetime)
end WherePred

namespace Param
  export ParamCore (named self_ variadic anon)
end Param

namespace RangePat
  export RangePatCore (literal path)
end RangePat

namespace FieldPat
  export FieldPatCore (shorthand full remaining)
end FieldPat

namespace ClosureParam
  export ClosureParamCore (pat typed)
end ClosureParam

namespace ClosureBody
  export ClosureBodyCore (expr block hole)
end ClosureBody

namespace LetChainItem
  export LetChainItemCore (expr let_)
end LetChainItem

namespace Condition
  export ConditionCore (expr let_ letChain)
end Condition

namespace ElseClause
  export ElseClauseCore (block elseIf)
end ElseClause

namespace MatchArm
  export MatchArmCore (mk)
end MatchArm

namespace FieldInit
  export FieldInitCore (shorthand full)
end FieldInit

namespace MacroInvocation
  export MacroInvocationCore (mk)
end MacroInvocation

namespace EiiImpl
  export EiiImplCore (mk)
end EiiImpl

namespace FnContract
  export FnContractCore (mk)
end FnContract

namespace InlineAsmOperand
  export InlineAsmOperandCore (in_ out inOut splitInOut const_ sym_ label_)
end InlineAsmOperand

namespace InlineAsm
  export InlineAsmCore (mk)
end InlineAsm
