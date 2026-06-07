module

public import LeanRustParser.ParserElabForTests

def asyncTests : List (String × String × String) := [
  ("async fn, no return type",
    ppSourceFile (rust async fn foo() {} end),
    "async fn foo() {\n  \n}"),
  ("async fn with return type",
    ppSourceFile (rust async fn foo() -> i32 {} end),
    "async fn foo() -> i32 {\n  \n}"),
  ("async fn with params and return type",
    ppSourceFile (rust async fn bar(x: i32, y: u64) -> bool {} end),
    "async fn bar(x: i32, y: u64) -> bool {\n  \n}"),
  ("pub async fn",
    ppSourceFile (rust pub async fn foo() -> i32 {} end),
    "pub async fn foo() -> i32 {\n  \n}"),
  ("plain fn",
    ppSourceFile (rust fn bar() {} end),
    "fn bar() {\n  \n}")
]
