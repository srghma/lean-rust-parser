module

public import LeanRustParser.CorpusParser
public import LeanRustParser.PrettyPrinter

@[expose] public section

def expectedMainSourceFile : SourceFile :=
  SourceFile.mk none [] [
    Item.fn_ [] none FnModifiers.none (Ident.mk "main") none [] none none
      (some (Block.mk none [] none)) none []
  ]

def renderParsedCorpus (src : String) : String :=
  match LeanRustParser.parseCorpusFile src with
  | .ok sf =>
      if sf == expectedMainSourceFile then
        ppSourceFile sf
      else
        s!"TREE MISMATCH: {repr sf}"
  | .error msg => s!"ERROR: {msg}"

def corpusTests : List (String × String × String) := [
  ("item-free-const-no-body-syntactic-pass.rs",
    renderParsedCorpus r#"
//@ check-pass

fn main() {}

#[cfg(false)]
const X: u8;
"#,
    "fn main() {}")
  ,
  ("item-free-static-no-body-syntactic-pass.rs",
    renderParsedCorpus r#"
//@ check-pass

fn main() {}

#[cfg(false)]
static X: u8;
"#,
    "fn main() {}")
  ,
  ("impl-item-fn-no-body-pass.rs",
    renderParsedCorpus r#"
//@ check-pass

fn main() {}

#[cfg(false)]
impl X {
    fn f();
}
"#,
    "fn main() {}")
  ,
  ("foreign-static-syntactic-pass.rs",
    renderParsedCorpus r#"
//@ check-pass

fn main() {}

#[cfg(false)]
extern "C" {
    static X: u8;
    static mut Y: u8;
}
"#,
    "fn main() {}")
]
