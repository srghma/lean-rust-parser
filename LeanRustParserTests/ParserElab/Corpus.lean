module

public import LeanRustParser.CorpusParser
public import LeanRustParser.PrettyPrinter

@[expose] public section

def corpusTests : List (String × String × String) := [
  ("item-free-const-no-body-syntactic-pass.rs",
    match LeanRustParser.parseCorpusFile r#"
//@ check-pass

fn main() {}

#[cfg(false)]
const X: u8;
"# with
    | .ok sf => ppSourceFile sf
    | .error msg => s!"ERROR: {msg}",
    "fn main() {}")
  ,
  ("item-free-static-no-body-syntactic-pass.rs",
    match LeanRustParser.parseCorpusFile r#"
//@ check-pass

fn main() {}

#[cfg(false)]
static X: u8;
"# with
    | .ok sf => ppSourceFile sf
    | .error msg => s!"ERROR: {msg}",
    "fn main() {}")
  ,
  ("impl-item-fn-no-body-pass.rs",
    match LeanRustParser.parseCorpusFile r#"
//@ check-pass

fn main() {}

#[cfg(false)]
impl X {
    fn f();
}
"# with
    | .ok sf => ppSourceFile sf
    | .error msg => s!"ERROR: {msg}",
    "fn main() {}")
]
