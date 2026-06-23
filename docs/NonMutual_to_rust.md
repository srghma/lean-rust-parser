The data types defined in your Lean 4 AST map directly to specific types inside the **Rust compiler AST (`rustc_ast`)** and the **`syn` crate** (the standard parser for procedural macros).

Below is a detailed map of where these Lean definitions reside in the Rust ecosystem.

---

### 1. Primitives, Identifiers, and Leaf Types
These are basic building blocks representing symbols and tokens.

* **`Ident`**
  * **`rustc_ast`**: `rustc_span::symbol::Ident` (stores an interned `Symbol` and a `Span`).
  * **`syn`**: `syn::Ident`.
* **`Lifetime`**
  * **`rustc_ast`**: `rustc_ast::Lifetime` (holds an identifier and a `NodeId`).
  * **`syn`**: `syn::Lifetime`.
* **`Label`**
  * **`rustc_ast`**: `rustc_ast::Label` (wraps an `Ident`).
  * **`syn`**: `syn::Label`.
* **`FragmentSpecifier`** (macro fragment matchers like `:expr`, `:block`)
  * **`rustc_ast`**: `rustc_ast::token::NonterminalKind` (defines matchers like `Item`, `Block`, `Stmt`, `Pat`, `Expr`, `Ty`, etc.).
  * **`syn`**: Handled internally during macro argument parsing.

---

### 2. Operators, Modifiers, and Bounds
These define operations, assignments, and trait bound properties.

* **`BinOp`** (binary operators)
  * **`rustc_ast`**: `rustc_ast::BinOpKind` (variants such as `Add`, `Sub`, `Mul`, `And`, `Or`, etc.)
  * **`syn`**: `syn::BinOp`.
* **`CompoundOp`** (compound assignments)
  * **`rustc_ast`**: `rustc_ast::AssignOpKind` (variants such as `AddAssign`, `SubAssign`, etc.)
  * **`syn`**: Represented as separate token structs or merged into `syn::BinOp`.
* **`UnaryOp`** (unary operators)
  * **`rustc_ast`**: `rustc_ast::UnOp` (contains `Deref`, `Not`, and `Neg`).
  * **`syn`**: `syn::UnOp`.
* **`RangeOp`** (range limits)
  * **`rustc_ast`**: Split between `rustc_ast::RangeLimits` (`HalfOpen` for `..`, `Closed` for `..=`) and `rustc_ast::RangeEnd`.
  * **`syn`**: `syn::RangeLimits`.
* **`TraitBoundModifier`** (trait object modifiers)
  * **`rustc_ast`**: Managed via the `rustc_ast::TraitBoundModifiers` struct, which contains fields for `BoundConstness`, `BoundAsyncness`, and `BoundPolarity`.
  * **`syn`**: `syn::TraitBoundModifier`.

---

### 3. Syntax Modifiers and Control Flow Properties
These map to options, keywords, and execution flags on expressions and statements.

* **`Visibility`**
  * **`rustc_ast`**: `rustc_ast::VisibilityKind` (variants like `Public`, `Restricted { path, id, shorthand }`, and `Inherited`).
  * **`syn`**: `syn::Visibility` (variants like `Public`, `Restricted`, and `Inherited`).
* **`CaptureBy`** (closure capture modes)
  * **`rustc_ast`**: `rustc_ast::CaptureBy` (variants like `Value { move_kw }`, `Ref`, and `Use { use_kw }`).
  * **`syn`**: `syn::Use` or `syn::Move` options on closures.
* **`GenBlockKind`** (coroutine markers)
  * **`rustc_ast`**: `rustc_ast::GenBlockKind` (variants like `Async`, `Gen`, and `AsyncGen`).
  * **`syn`**: Custom attributes or keyword tracking.
* **`MatchKind`** (postfix match)
  * **`rustc_ast`**: `rustc_ast::MatchKind` (variants like `Prefix` and `Postfix`).
* **`YieldKind`** (postfix yield)
  * **`rustc_ast`**: `rustc_ast::YieldKind` (variants like `Prefix(Option<Box<Expr>>)` and `Postfix(Box<Expr>)`).
* **`ForLoopKind`** (`for await` loops)
  * **`rustc_ast`**: `rustc_ast::ForLoopKind` (variants like `For` and `ForAwait`).
* **`UnsafeBinderCastKind`**
  * **`rustc_ast`**: `rustc_ast::UnsafeBinderCastKind` (variants like `Wrap` and `Unwrap`).
* **`MacStmtStyle`** (macro termination)
  * **`rustc_ast`**: `rustc_ast::MacStmtStyle` (variants like `Semicolon`, `Braces`, and `NoBraces`).

---

### 4. Literals, Function Modifiers, and Structural Elements
These capture value representations and compound function headers.

* **`Literal`**
  * **`rustc_ast`**: `rustc_ast::LitKind` (defined as `Str`, `ByteStr`, `CStr`, `Byte`, `Char`, `Int`, `Float`, `Bool`, and `Err`).
  * **`syn`**: `syn::Lit` (which similarly divides into sub-structs like `LitStr`, `LitInt`, etc.).
* **`FnModifiers`** (function header configuration)
  * **`rustc_ast`**: This is a flattened translation of **`rustc_ast::FnHeader`** (containing `constness`, `coroutine_kind`, `safety`, and `ext: Extern`) combined with **`rustc_ast::Defaultness`**.
  * **`syn`**: Represented as optional flags (e.g., `asyncness`, `constness`, `unsafety`, `abi`) on signature structs.

---

### 5. Macros and Imports (Token Trees and Use Trees)
These represent parsed token groups and recursive import structures.

* **`TokenTree`** (opaque macro content storage)
  * **`rustc_ast`**: `rustc_ast::tokenstream::TokenTree` (usually a recursive `Token` or `Delimited` sequence).
  * **`syn`**: `proc_macro2::TokenTree` (divided into `Group`, `Ident`, `Punct`, and `Literal`).
* **`MacroRule`** (declarative macro matchers)
  * **`rustc_ast`**: Represented within `rustc_ast::MacroDef` or parsed patterns.
  * **`syn`**: Part of procedural parsing logic.
* **`UseTree`** (import path trees)
  * **`rustc_ast`**: `rustc_ast::UseTreeKind` (variants like `Simple(Option<Ident>)`, `Nested { items, span }`, and `Glob(Span)`).
  * **`syn`**: **`syn::UseTree`**. Your Lean implementation is an exact 1:1 match of the `syn` representation:
    * `UseTree::path` $\rightarrow$ `syn::UsePath`
    * `UseTree::name` $\rightarrow$ `syn::UseName`
    * `UseTree::alias` $\rightarrow$ `syn::UseRename`
    * `UseTree::glob` $\rightarrow$ `syn::UseGlob`
    * `UseTree::list` $\rightarrow$ `syn::UseGroup`
