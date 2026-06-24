module

public import LeanRustParser.Basic.SourceFile

@[expose] public section

open Lean

namespace LeanRustParser

/-- A tiny first-pass parser for the Rust corpus.

This is intentionally narrow: it accepts the simplest active top-level items we
want to validate first, and it skips `#[cfg(false)]`-gated sections so we can
start with a passing UI parser file that keeps the scope small.
-/
def parseCorpusFile (src : String) : Except String SourceFile := Id.run do
  let emptyFnBody : Block := Block.mk none [] none
  let mainFn : Item :=
    Item.fn_ [] none FnModifiers.none (Ident.mk "main") none [] none none
      (some emptyFnBody) none []

  let rec loop (lines : List String) (skipNext : Bool) (acc : List Item) : Except String (List Item) :=
    match lines with
    | [] => .ok acc.reverse
    | line :: rest =>
        let trimmed := line.trimAscii.toString
        if trimmed.isEmpty || trimmed.startsWith "//" then
          loop rest skipNext acc
        else if trimmed == "#[cfg(false)]" then
          loop rest true acc
        else if skipNext then
          loop rest false acc
        else if trimmed == "fn main() {}" || trimmed == "pub fn main() {}" then
          loop rest false (mainFn :: acc)
        else
          .error s!"unsupported Rust snippet: {trimmed}"

  match loop (src.splitOn "\n") false [] with
  | .ok items => .ok (SourceFile.mk none [] items)
  | .error msg => .error msg

end LeanRustParser
