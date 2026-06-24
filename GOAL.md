lets forget about elab for now, lets implement parser of rust

into /home/srghma/projects/lean-rust-parser/rust-tests-ui-parser I have copied tests/ui/parser/ folder from rust repo /home/srghma/projects/rust/tests/ui/parser

it contains tests that should and should not pass

lets concentrate for now only on files that should pass

lets start from 1 such .rs file

add a parser

then test that it parses without errors at LeanRustParserTests/Main.lean

parser should use https://leanprover-community.github.io/mathlib4_docs/Lean/Parser/Basic.html to parse text into LeanRustParser/Basic/SourceFile.lean
