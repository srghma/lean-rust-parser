module

public import LeanRustParser.ParserElabForTests

@[expose] public section

def sourceFilesTests : List (String × String × String) := [
--   ("Greek letters in identifiers",
--     ppSourceFile (rust
--       const σ1 : Σ = 0;
--       const ψ_2 : Ψ = 1;
--     end),
--     r#"
-- const σ1 : Σ = 0;
-- const ψ_2 : Ψ = 1;"#),
--   ("shebang line containing spaces",
--     ppSourceFile (rust #!/usr/bin/env -S cargo +nightly -Zscript end),
--     "#!/usr/bin/env -S cargo +nightly -Zscript"),
--   ("empty shebang with code after",
--     ppSourceFile (rust
--       #!
--       fn main() {}
--     end),
--     r#"#!
-- fn main() {}"#),
--   ("immediate inner attribute",
--     ppSourceFile (rust
--       #![feature(thing)]
--       fn main() {}
--     end),
--     r#"#![feature(thing)]
-- fn main() {}"#)
]
