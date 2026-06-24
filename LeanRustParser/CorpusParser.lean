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

  let braceDelta (s : String) : Int :=
    s.toList.foldl
      (fun acc c =>
        if c = '{' then acc + 1
        else if c = '}' then acc - 1
        else acc) 0

  let rec loop (lines : List String) (skip : Option Int) (acc : List Item) : Except String (List Item) :=
    match lines with
    | [] => .ok acc.reverse
    | line :: rest =>
        let trimmed := line.trimAscii.toString
        if trimmed.isEmpty || trimmed.startsWith "//" then
          loop rest skip acc
        else if trimmed == "#[cfg(false)]" then
          loop rest (some 0) acc
        else
          match skip with
          | some depth =>
              let delta := braceDelta trimmed
              if depth = 0 then
                if delta > 0 then
                  loop rest (some delta) acc
                else
                  loop rest none acc
              else
                let nextDepth := depth + delta
                if nextDepth <= 0 then
                  loop rest none acc
                else
                  loop rest (some nextDepth) acc
          | none =>
              if trimmed == "fn main() {}" || trimmed == "pub fn main() {}" then
                loop rest none (mainFn :: acc)
              else
                .error s!"unsupported Rust snippet: {trimmed}"

  match loop (src.splitOn "\n") none [] with
  | .ok items => .ok (SourceFile.mk none [] items)
  | .error msg => .error msg

end LeanRustParser
