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
    "fn bar() {}"),
  ("async fn abc",
    ppSourceFile (rust async fn abc() {} end),
    "async fn abc() {}"),
  ("async fn main with await",
    ppSourceFile (rust
      async fn main() {
        let x = futures.await?;
      }
    end),
    "async fn main() {\n  let x = futures.await?;\n}"),
  ("futures await chaining",
    ppSourceFile (rust
      fn test() {
        futures.await;
        futures.await?;
        futures.await?.await?;
        futures.await?.function().await?;
      }
    end),
    "fn test() {\n  futures.await;\n  futures.await?;\n  futures.await?.await?;\n  futures.await?.function\n  ().await?;\n}"),
  ("async blocks",
    ppSourceFile (rust
      fn test() {
        async {};
        async { let x = 10; };
        async move {};
      }
    end),
    "fn test() {\n  async {};\n  async {\n    let x = 10;\n  };\n  async move {};\n}"),
  ("async closures",
    ppSourceFile (rust
      fn test() {
        let _ = async || ();
        let a = async move || async move {};
      }
    end),
    "fn test() {\n  let _ = async || ();\n  let a = async move || async move {};\n}"),
  ("try block",
    ppSourceFile (rust
      fn test() {
        try {};
      }
    end),
    "fn test() {\n  try {};\n}"),
  ("gen blocks and yield",
    ppSourceFile (rust
      fn test() {
        gen {};
        gen { let x = 10; };
        gen { yield (); };
        gen move {};
      }
    end),
    "fn test() {\n  gen {};\n  gen {\n    let x = 10;\n  };\n  gen {\n    yield ();\n  };\n  gen move {};\n}")
]
