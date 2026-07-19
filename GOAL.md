lets forget about elab for now, lets implement parser of rust

into /home/srghma/projects/lean-rust-parser/rust-tests-ui-parser I have copied tests/ui/parser/ folder from rust repo /home/srghma/projects/rust/tests/ui/parser

it contains tests that should and should not pass

lets concentrate for now only on files that should pass

lets start from 1 such .rs file. Copy it to ./LeanRustParserTests/rust-code-should-parse/xxx.rs

(maybe add a lexer)

add parser

then test that it parses without errors at LeanRustParserTests/Main.lean

then prints into ./LeanRustParserTests/rust-code-should-parse--after-printing/xxx.rs

parser should use https://leanprover-community.github.io/mathlib4_docs/Lean/Parser/Basic.html
