module

public import LeanRustParser.CorpusParser
public import LeanRustParserTests.ParserElab.Corpus
public import LeanRustParserTests.ParserElab.Async
public import LeanRustParserTests.ParserElab.Declarations
public import LeanRustParserTests.ParserElab.Expressions
public import LeanRustParserTests.ParserElab.Literals
public import LeanRustParserTests.ParserElab.Macros
public import LeanRustParserTests.ParserElab.Patterns
public import LeanRustParserTests.ParserElab.SourceFiles
public import LeanRustParserTests.ParserElab.Types

@[expose] public section

def tests := [
  ("Async", asyncTests),
  ("Corpus", corpusTests),
  ("Declarations", declarationsTests),
  ("Expressions", expressionsTests),
  ("Literals", literalsTests),
  ("Macros", macrosTests),
  ("Patterns", patternsTests),
  ("SourceFiles", sourceFilesTests),
  ("Types", typesTests),
]

def runTests (tests : List (String × String × String)) : IO Bool := do
  let mut allOk := true
  for (name, got, expected) in tests do
    if got == expected then
      IO.println s!"  ✅ {name}"
    else
      IO.println s!"  ❌ {name}"
      IO.println s!"     expected: {repr expected}"
      IO.println s!"     got:      {repr got}"
      allOk := false
  return allOk

def main : IO UInt32 := do
  let allOk <- tests.foldlM (fun acc (name, tests) => do
    IO.println s!"=== {name} ==="
    let ok <- runTests tests
    return acc && ok
  ) true
  if allOk then
    IO.println "All tests passed."
    return 0
  else
    IO.println "Some tests FAILED."
    return 1
