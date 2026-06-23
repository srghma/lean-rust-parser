Because `rustc_ast` only defines the data structures of the Abstract Syntax Tree (such as `Expr`, `Pat`, and `Item`), it does not contain the logic for parsing text strings into those structures.

Consequently, the parser tests—which verify how Rust source text is translated into the AST—are split between unit tests in the parser crate (`rustc_parse`) and comprehensive integration tests in the main `tests/ui` directory of the repository.

---

### 1. Parser Unit Tests (`rustc_parse`)
The unit tests that directly invoke the parser programmatically to verify that strings of Rust code correctly produce the expected AST structures are located in the **`rustc_parse`** crate:

* **`compiler/rustc_parse/src/parser/tests.rs`**
  *(Contains test functions verifying that the parser handles specific expressions, items, types, and recovery paths correctly.)*
* **`compiler/rustc_parse/src/parser/tokenstream/tests.rs`**
  *(Contains tests checking how token trees and macros are parsed into streams.)*

As the developers note in a comment inside `compiler/rustc_parse/src/parser/mod.rs`:
> *"Ideally, these tests would be in `rustc_ast`. But they depend on having a parser, so they are here."*

---

### 2. Integration and UI Tests (`tests/ui/parser/`)
The primary suite for testing frontend grammar, syntactical edge cases, error diagnostics, and parser recovery is located under the global **`tests/ui`** directory at the root of the Rust repository.

* **`tests/ui/parser/`**
  This directory contains hundreds of `.rs` files testing both valid and invalid syntax. Compiletest runs these files against `rustc` and compares the console output (syntax errors, warnings, recovery suggestions) against adjacent `.stderr` or `.stdout` files.
* **`tests/ui/parser/issues/`**
  Contains parser regression tests associated with specific GitHub issues.
* **`tests/ui/weird-exprs.rs`**
  A test file containing syntactically valid but bizarrely-constructed Rust expressions, ensuring the parser handles complex nesting and unusual operator spacing safely.
* **`tests/ui/parser/bastion-of-the-turbofish.rs`**
  The canonical file testing the ambiguities around the `::<>` turbofish syntax.
