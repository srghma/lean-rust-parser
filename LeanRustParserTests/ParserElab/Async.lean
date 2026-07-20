module

public import LeanRustParser.ParserElabForTests
public import LeanRustParser.PrettyPrinter

@[expose] public section

def asyncTests : List (String × String × String) := [
  ("async function without return type",
    ppSourceFile (rust async fn foo() {} end),
    "async fn foo() {}"),
  ("async function with return type",
    ppSourceFile (rust async fn foo() -> i32 {} end),
    "async fn foo() -> i32 {}"),
  ("async function with parameters and return type",
    ppSourceFile (rust async fn bar(x: i32, y: u64) -> bool {} end),
    "async fn bar(x: i32, y: u64) -> bool {}"),
  ("public async function",
    ppSourceFile (rust pub async fn foo() -> i32 {} end),
    "pub async fn foo() -> i32 {}"),
  ("standard plain function",
    ppSourceFile (rust fn bar() {} end),
    "fn bar() {}"),
  ("async function definition",
    ppSourceFile (rust async fn abc() {} end),
    "async fn abc() {}"),
  ("async function main with await expression",
    ppSourceFile (rust
      async fn main() {
        let x = futures.await?;
      }
    end),
    r#"async fn main() {
  let x = futures.await?;
}"#),
  ("futures await chaining",
    ppSourceFile (rust
      fn test() {
        futures.await;
        futures.await?;
        futures.await?.await?;
        futures.await?.function().await?;
      }
    end),
    r#"fn test() {
  futures.await;
  futures.await?;
  futures.await?.await?;
  futures.await?.function
  ().await?;
}"#),
  ("async block expressions",
    ppSourceFile (rust
      fn test() {
        async {};
        async { let x = 10; };
        async move {};
      }
    end),
    r#"fn test() {
  async {};
  async {
    let x = 10;
  };
  async move {};
}"#),
  ("async closure expressions",
    ppSourceFile (rust
      fn test() {
        let _ = async || ();
        let a = async move || async move {};
      }
    end),
    r#"fn test() {
  let _ = async || ();
  let a = async move || async move {};
}"#),
  ("try block expression",
    ppSourceFile (rust
      fn test() {
        try {};
      }
    end),
    r#"fn test() {
  try {};
}"#),
  ("generator blocks and yield expressions",
    ppSourceFile (rust
      fn test() {
        gen {};
        gen { let x = 10; };
        gen { yield (); };
        gen move {};
      }
    end),
    r#"fn test() {
  gen {};
  gen {
    let x = 10;
  };
  gen {
    yield ();
  };
  gen move {};
}"#)
]
