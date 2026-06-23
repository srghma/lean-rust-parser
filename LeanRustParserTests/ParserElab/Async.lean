module

public import LeanRustParser.ParserElabForTests

@[expose] public section

def asyncTests : List (String × String × String) := [
  ("async fn, no return type",
    ppSourceFile (rust async fn foo() {} end),
    "async fn foo() {}"),
  ("async fn with return type",
    ppSourceFile (rust async fn foo() -> i32 {} end),
    "async fn foo() -> i32 {}"),
  ("async fn with params and return type",
    ppSourceFile (rust async fn bar(x: i32, y: u64) -> bool {} end),
    "async fn bar(x: i32, y: u64) -> bool {}"),
  ("pub async fn",
    ppSourceFile (rust pub async fn foo() -> i32 {} end),
    "pub async fn foo() -> i32 {}"),
  ("plain fn",
    ppSourceFile (rust fn bar() {} end),
    "fn bar() {}")
]
