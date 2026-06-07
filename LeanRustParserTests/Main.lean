module
import Std
import LeanRustParserTests.ParserElab.Async

def runTests (tests : List (String × String × String)) : IO Bool := do
  let mut allOk := true
  for (name, got, expected) in tests do
    if got == expected then
      IO.println s!"  ok: {name}"
    else
      IO.println s!"  FAIL: {name}"
      IO.println s!"    expected: {repr expected}"
      IO.println s!"    got:      {repr got}"
      allOk := false
  return allOk

def main : IO UInt32 := do
  IO.println "=== Async ==="
  let ok <- runTests asyncTests
  if ok then
    IO.println "All tests passed."
    return 0
  else
    IO.println "Some tests FAILED."
    return 1
