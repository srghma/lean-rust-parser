module

public import LeanRustParserTests.ParserElab.Async
public import LeanRustParserTests.ParserElab.Declarations
public import LeanRustParserTests.ParserElab.Expressions
public import LeanRustParserTests.ParserElab.Literals
public import LeanRustParserTests.ParserElab.Macros
public import LeanRustParserTests.ParserElab.Patterns
public import LeanRustParserTests.ParserElab.SourceFiles
public import LeanRustParserTests.ParserElab.Types
public import LeanRustParser.RustParser
public import LeanRustParser.PrettyPrinter

@[expose] public section

open System
open LeanRustParser

def tests := [
  ("Async", asyncTests),
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

def rustCodeDir : FilePath := FilePath.mk "LeanRustParserTests/rust-code"
def rustOutputDir : FilePath := FilePath.mk "LeanRustParserTests/rust-code--output-of-lean-prettyprint"
def rustParserStatePath : FilePath := rustOutputDir / ".parsed-state"
def rustEditions : List RustEdition := [.e2015, .e2018, .e2021, .e2024]

def rustEditionName : RustEdition → String
  | .e2015 => "2015"
  | .e2018 => "2018"
  | .e2021 => "2021"
  | .e2024 => "2024"

universe u

inductive RustEditionWithData (α : Type u) where
  | editions (e2015 : α) (e2018 : α) (e2021 : α) (e2024 : α)
  deriving Repr

def RustEditionWithData.get {α : Type u} (values : RustEditionWithData α) : RustEdition → α
  | .e2015 => let .editions data _ _ _ := values; data
  | .e2018 => let .editions _ data _ _ := values; data
  | .e2021 => let .editions _ _ data _ := values; data
  | .e2024 => let .editions _ _ _ data := values; data

def RustEditionWithData.all {α : Type u} (p : α → Bool) : RustEditionWithData α → Bool
  | .editions e2015 e2018 e2021 e2024 => p e2015 && p e2018 && p e2021 && p e2024

inductive RustParserStage where
  | sourceParse | commentFreeComparison | prettyprintParse | astBeq
  deriving Repr, DecidableEq, Ord

def rustParserStageName : RustParserStage → String
  | .sourceParse => "source-parse"
  | .commentFreeComparison => "comment-free-comparison"
  | .prettyprintParse => "prettyprint-parse"
  | .astBeq => "ast-beq"

def stageEnabled (upToStage stage : RustParserStage) : Bool := compare stage upToStage != .gt

def rustCodeFiles : IO (List FilePath) := do
  let paths ← rustCodeDir.walkDir
  return (paths.toList.filter (fun path => path.extension == some "rs" &&
      !path.toString.endsWith "-without-comments.rs")).mergeSort
    (fun left right => left.toString < right.toString)

def rustStatus (path : FilePath) : IO (RustEditionWithData Bool) := do
  let some name := path.fileName | throw <| IO.userError s!"Fixture has no filename: {path}"
  let some last := name.splitOn "-" |>.getLast? | throw <| IO.userError s!"Fixture has no status suffix: {path}"
  let suffix := (last.take (last.length - 3)).toString
  if suffix.length != 4 || !suffix.toList.all (fun c => c == 'f' || c == 't') then
    throw <| IO.userError s!"Fixture has invalid edition status suffix '{suffix}': {path}"
  match suffix.toList with
  | [e2015, e2018, e2021, e2024] =>
      return .editions (e2015 == 't') (e2018 == 't') (e2021 == 't') (e2024 == 't')
  | _ => throw <| IO.userError s!"Fixture has invalid edition status suffix '{suffix}': {path}"

def rustWithoutCommentsPath (path : FilePath) : FilePath :=
  let stem := (path.toString.splitOn ".rs").head?.getD ""
  FilePath.mk (stem ++ "-without-comments.rs")

def rustOutputPath (path : FilePath) : FilePath :=
  rustOutputDir / (path.fileName.getD "output.rs")

-- -- should remove all empty lines
-- -- then should transform all `\s` (newlines and tabs including) to only one space
-- def compactWhitespace (source : String) : String :=
--   let (reversed, pendingWhitespace) := source.toList.foldl
--     (fun (acc, pending) character =>
--       if character.isWhitespace then
--         (acc, true)
--       else if pending then
--         (character :: ' ' :: acc, false)
--       else
--         (character :: acc, false))
--     ([], false)
--   let reversed := if pendingWhitespace then ' ' :: reversed else reversed
--   (String.ofList reversed.reverse).trimAscii.toString

/-- Compare source text independently of its whitespace layout. -/
def stripWhitespace (source : String) : String :=
  String.ofList (source.toList.filter (!·.isWhitespace))

def sourceFingerprint (path : FilePath) (source : String) : String :=
  s!"{path}\t{String.hash source}"

def readParserState : IO (List String) := do
  if ← rustParserStatePath.pathExists then
    return (← IO.FS.readFile rustParserStatePath).splitOn "\n" |>.filter (!·.isEmpty)
  return []

def report (compactOutput : Bool) (message : String) : IO Unit := do
  if !compactOutput then
    IO.println message
  else
    pure PUnit.unit

def charIndex? (needle : Char) : List Char → Option Nat
  | [] => none
  | character :: rest =>
      if character == needle then
        some 0
      else
        (charIndex? needle rest).map (· + 1)

def red (text : String) : String := "\x1b[31m" ++ text ++ "\x1b[0m"
def green (text : String) : String := "\x1b[32m" ++ text ++ "\x1b[0m"

def visibleDiffChars (characters : List Char) : String :=
  String.intercalate "" <| characters.map fun
    | ' ' => "·"
    | character => String.ofList [character]

partial def inlineCharDiff : List Char → List Char → List String × List String
  | [], [] => ([], [])
  | expected, [] => ([red (visibleDiffChars expected)], [])
  | [], actual => ([], [green (visibleDiffChars actual)])
  | expectedHead :: expectedTail, actualHead :: actualTail =>
      if expectedHead == actualHead then
        let (expectedParts, actualParts) := inlineCharDiff expectedTail actualTail
        let shared := String.ofList [expectedHead]
        (shared :: expectedParts, shared :: actualParts)
      else
        match charIndex? actualHead expectedTail, charIndex? expectedHead actualTail with
        | some expectedOffset, _ =>
            let (expectedParts, actualParts) := inlineCharDiff (expectedTail.drop expectedOffset) (actualHead :: actualTail)
            (red (visibleDiffChars (expectedHead :: expectedTail.take expectedOffset)) :: expectedParts, actualParts)
        | none, some actualOffset =>
            let (expectedParts, actualParts) := inlineCharDiff (expectedHead :: expectedTail) (actualTail.drop actualOffset)
            (expectedParts, green (visibleDiffChars (actualHead :: actualTail.take actualOffset)) :: actualParts)
        | none, none =>
            let (expectedParts, actualParts) := inlineCharDiff expectedTail actualTail
            (red (visibleDiffChars [expectedHead]) :: expectedParts, green (visibleDiffChars [actualHead]) :: actualParts)

def commentFreeComparisonDiff (expected actual : String) : String :=
  let (expectedParts, actualParts) := inlineCharDiff expected.toList actual.toList
  "      diff (- expected, + actual):\n" ++
    "      - " ++ String.intercalate "" expectedParts ++ "\n" ++
    "      + " ++ String.intercalate "" actualParts

inductive AiTestFailure where
  | sourceParseAccepted
  | sourceParseError (message : String)
  | commentFreeComparison
  | prettyprintParseError (message : String)
  | astNotEqual
  deriving Repr

inductive HumanTestLog where
  | sourceParseRejected
  | sourceParseSucceeded
  | sourceParseFailed (message : String)
  | sourceParseUnexpectedlySucceeded
  | commentFreeComparisonSucceeded
  | commentFreeComparisonFailed (diff : String)
  | prettyprintParseSucceeded
  | prettyprintParseFailed (message : String)
  | astBeqSucceeded
  | astBeqFailed
  deriving Repr

structure LogOfOneTest where
  forHuman : List HumanTestLog
  forAi : List AiTestFailure

def LogOfOneTest.empty : LogOfOneTest := ⟨[], []⟩

def LogOfOneTest.addHuman (log : LogOfOneTest) (event : HumanTestLog) : LogOfOneTest :=
  { log with forHuman := log.forHuman.concat event }

def LogOfOneTest.addAi (log : LogOfOneTest) (failure : AiTestFailure) : LogOfOneTest :=
  { log with forAi := log.forAi.concat failure }

def AiTestFailure.compact (edition : RustEdition) : AiTestFailure → String
  | .sourceParseAccepted => s!"{rustEditionName edition}:S!"
  | .sourceParseError message => s!"{rustEditionName edition}:S?{repr message}"
  | .commentFreeComparison => s!"{rustEditionName edition}:C"
  | .prettyprintParseError message => s!"{rustEditionName edition}:P?{repr message}"
  | .astNotEqual => s!"{rustEditionName edition}:A"

def HumanTestLog.render : HumanTestLog → String
  | .sourceParseRejected => "      ✅ stage source-parse: rejected as expected"
  | .sourceParseSucceeded => "      ✅ stage source-parse"
  | .sourceParseFailed message => s!"      ❌ stage source-parse: {message}"
  | .sourceParseUnexpectedlySucceeded => "      ❌ stage source-parse: accepted but failure was expected"
  | .commentFreeComparisonSucceeded => "      ✅ stage comment-free-comparison"
  | .commentFreeComparisonFailed diff => "      ❌ stage comment-free-comparison\n" ++ diff
  | .prettyprintParseSucceeded => "      ✅ stage prettyprint-parse"
  | .prettyprintParseFailed message => s!"      ❌ stage prettyprint-parse: {message}"
  | .astBeqSucceeded => "      ✅ stage ast-beq"
  | .astBeqFailed => "      ❌ stage ast-beq"

def HumanTestLog.commentFreeDiff? : HumanTestLog → Option String
  | .commentFreeComparisonFailed diff => some diff
  | _ => none

def shouldFailParsing (input : String) (edition : RustEdition) (_compactOutput : Bool) : IO LogOfOneTest := do
  match ← LeanRustParser.parseSourceFile input edition with
  | .error _ =>
      return LogOfOneTest.empty.addHuman .sourceParseRejected
  | .ok _ =>
      return (LogOfOneTest.empty.addHuman .sourceParseUnexpectedlySucceeded).addAi .sourceParseAccepted

def shouldParseAndPassOtherStages (inputPath : FilePath) (input : String) (edition : RustEdition)
    (upToStage : RustParserStage) : IO LogOfOneTest := do
  let mut log := LogOfOneTest.empty
  let sourceFile? ← match ← LeanRustParser.parseSourceFile input edition with
    | .ok sourceFile =>
        log := log.addHuman .sourceParseSucceeded
        pure (some sourceFile)
    | .error message =>
        log := (log.addHuman (.sourceParseFailed message)).addAi (.sourceParseError message)
        pure none
  let some sourceFile := sourceFile? | return log
  let withoutCommentsPath := rustWithoutCommentsPath inputPath
  if !(← withoutCommentsPath.pathExists) then
    throw <| IO.userError s!"Missing comment-free companion for {inputPath}: {withoutCommentsPath}"
  let withoutComments ← IO.FS.readFile withoutCommentsPath
  let printed := ppSourceFile sourceFile
  if stageEnabled upToStage .commentFreeComparison then
    let expected := stripWhitespace withoutComments
    let actual := stripWhitespace printed
    if actual == expected then
      log := log.addHuman .commentFreeComparisonSucceeded
    else
      log := (log.addHuman (.commentFreeComparisonFailed (commentFreeComparisonDiff expected actual))).addAi .commentFreeComparison
  if stageEnabled upToStage .prettyprintParse then
    match ← LeanRustParser.parseSourceFile printed edition with
    | .error message =>
        log := (log.addHuman (.prettyprintParseFailed message)).addAi (.prettyprintParseError message)
    | .ok reparsed =>
        log := log.addHuman .prettyprintParseSucceeded
        if stageEnabled upToStage .astBeq then
          if sourceFile == reparsed then log := log.addHuman .astBeqSucceeded
          else
            log := (log.addHuman .astBeqFailed).addAi .astNotEqual
  IO.FS.writeFile (rustOutputPath inputPath) printed
  return log

def runRustFileParserTests (upToStage : RustParserStage) (skipAlreadyPassed : Bool := false)
    (stopOnFirstError : Bool := false) (compactOutput : Bool := false)
    (only : Option (List String) := none) (except : List String := []) : IO Bool := do
  IO.FS.createDirAll rustOutputDir
  let allFiles ← rustCodeFiles
  let included := match only with
    | none => allFiles
    | some names => allFiles.filter fun path => names.contains (path.fileName.getD "")
  let files := included.filter fun path => !except.contains (path.fileName.getD "")
  let initialParsed ← if skipAlreadyPassed then readParserState else pure []
  let mut parsed := initialParsed
  let mut allOk := true
  for inputPath in files do
    let expected ← rustStatus inputPath
    let input ← IO.FS.readFile inputPath
    let fingerprint := sourceFingerprint inputPath input
    if skipAlreadyPassed && parsed.contains fingerprint then
      report compactOutput s!"  {inputPath.toString}"
      report compactOutput "    ⏭️ skipped (already passed)"
      continue
    let displayPath := inputPath.toString.drop (rustCodeDir.toString.length + 1)
    report compactOutput s!"  {displayPath}"
    let mut allFileOk := true
    let mut compactFailures : List String := []
    let mut compactDiff : Option String := none
    for edition in rustEditions do
      let shouldParse := expected.get edition
      report compactOutput s!"    edition {rustEditionName edition} ({if shouldParse then "parse" else "fail"})"
      let log ← if shouldParse then
        shouldParseAndPassOtherStages inputPath input edition upToStage
      else
        shouldFailParsing input edition compactOutput
      for message in log.forHuman do
        report compactOutput message.render
        if compactDiff.isNone then
          compactDiff := message.commentFreeDiff?
      compactFailures := compactFailures ++ log.forAi.map (AiTestFailure.compact edition)
      if !log.forAi.isEmpty then
        allFileOk := false
    if compactOutput && !compactFailures.isEmpty then
      if let some diff := compactDiff then
        IO.println s!"D {displayPath}\n{diff}"
      IO.println s!"F {displayPath} {String.intercalate " " compactFailures}"
    if allFileOk then
      if skipAlreadyPassed then
        parsed := fingerprint :: parsed
        IO.FS.writeFile rustParserStatePath (String.intercalate "\n" parsed ++ "\n")
    else
      allOk := false
      if stopOnFirstError then return false
  return allOk

def parserStageFromName : String → Option RustParserStage
  | "source-parse" | "sourceParse" => some .sourceParse
  | "comment-free-comparison" | "commentFreeComparison" => some .commentFreeComparison
  | "prettyprint-parse" | "prettyprintParse" => some .prettyprintParse
  | "ast-beq" | "astBeq" => some .astBeq
  | _ => none

def upToStageFromArgs (args : List String) : RustParserStage :=
  args.find? (·.startsWith "--up-to-stage=") |>.bind
    (fun argument => parserStageFromName (argument.drop "--up-to-stage=".length).toString) |>.getD .astBeq

def onlyFromArgs (args : List String) : Option (List String) :=
  args.find? (·.startsWith "--only=") |>.map
    (fun argument => (argument.drop "--only=".length).toString.splitOn "|" |>.filter (!·.isEmpty))

def exceptFromArgs (args : List String) : List String :=
  args.find? (·.startsWith "--except=") |>.map
    (fun argument => (argument.drop "--except=".length).toString.splitOn "|" |>.filter (!·.isEmpty)) |>.getD []

def main (args : List String) : IO UInt32 := do
  let stopOnFirstError := args.contains "--stop-on-first-error"
  let skipAlreadyPassed := args.contains "--skip-already-passed"
  let compactOutput := args.contains "--compact-output"
  let only := onlyFromArgs args
  let except := exceptFromArgs args
  let upToStage := upToStageFromArgs args
  let allOk ← if compactOutput then
    pure true
  else
    tests.foldlM (fun acc (name, tests) => do
      IO.println s!"=== {name} ==="
      let ok ← runTests tests
      return acc && ok
    ) true
  report compactOutput s!"=== Rust file parser; up to {rustParserStageName upToStage} ==="
  let fileParserOk ← runRustFileParserTests upToStage skipAlreadyPassed stopOnFirstError compactOutput only except
  let allOk := allOk && fileParserOk
  if allOk then
    report compactOutput "All tests passed."
    return 0
  else
    report compactOutput "Some tests FAILED."
    return 1
