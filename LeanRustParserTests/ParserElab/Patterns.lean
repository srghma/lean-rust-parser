module

public import LeanRustParser.ParserElabForTests

@[expose] public section

def patternsTests : List (String × String × String) := [
--   ("tuple struct patterns",
--     ppSourceFile (rust
--       match x {
--         Some(x) => "some",
--         std::None() => "none"
--       }
--     end),
--     r#"match x {
--   Some(x) => "some",
--   std::None() => "none"
-- }"#),
--   ("reference patterns",
--     ppSourceFile (rust
--       match x {
--         A(ref x) => x.0,
--         ref mut y => y,
--         & mut  z => z,
--       }
--     end),
--     r#"match x {
--   A(ref x) => x.0,
--   ref mut y => y,
--   & mut  z => z,
-- }"#),
--   ("struct patterns",
--     ppSourceFile (rust
--       match x {
--         Person{name, age} if age < 5 => ("toddler", name),
--         Person{name: adult_name, age: _} => ("adult", adult_name),
--       }

--       match y {
--         Bar::T1(_, Some::<isize>(x)) => println!("{x}"),
--       }
--     end),
--     r#"match x {
--   Person{name, age} if age < 5 => ("toddler", name),
--   Person{name: adult_name, age: _} => ("adult", adult_name),
-- }

-- match y {
--   Bar::T1(_, Some::<isize>(x)) => println!("{x}"),
-- }"#),
--   ("ignored patterns",
--     ppSourceFile (rust
--       match x {
--         (a, ..) => a,
--         B(..) => c,
--         D::E{f: g, ..} => g
--       }
--     end),
--     r#"match x {
--   (a, ..) => a,
--   B(..) => c,
--   D::E{f: g, ..} => g
-- }"#),
--   ("captured patterns",
--     ppSourceFile (rust
--       match x {
--         a @ A(_) | b @ B(..) => a,
--         a @ 1 ... 5 => a,
--         Some(1 ... 5) => a,
--         a @ b...c => a,
--         a @ b..=c => a,
--         d.. => a,
--         ..d => d,
--         a @ ..=5 => a
--       }

--       match name {
--         | "IPV6_FLOWINFO"
--         | "IPV6_FLOWLABEL_MGR"
--         | "IPV6_FLOWINFO_SEND" => true,
--         _ => false,
--       }
--     end),
--     r#"match x {
--   a @ A(_) | b @ B(..) => a,
--   a @ 1 ... 5 => a,
--   Some(1 ... 5) => a,
--   a @ b...c => a,
--   a @ b..=c => a,
--   d.. => a,
--   ..d => d,
--   a @ ..=5 => a
-- }

-- match name {
--   | "IPV6_FLOWINFO"
--   | "IPV6_FLOWLABEL_MGR"
--   | "IPV6_FLOWINFO_SEND" => true,
--   _ => false,
-- }"#),
--   ("or patterns",
--     ppSourceFile (rust
--       if let A(x) | B(x) = expr {
--           do_stuff_with(x);
--       }

--       while let A(x) | B(x) = expr {
--           do_stuff_with(x);
--       }

--       let Ok(index) | Err(index) = slice.binary_search(&x);

--       for ref a | b in c {}

--       let Ok(x) | Err(x) = binary_search(x);

--       for A | B | C in c {}

--       |(Ok(x) | Err(x))| expr();

--       let ref mut x @ (A | B | C);

--       fn foo((1 | 2 | 3): u8) {}

--       if let x!() | y!() = () {}
--     end),
--     r#"if let A(x) | B(x) = expr {
--     do_stuff_with(x);
-- }

-- while let A(x) | B(x) = expr {
--     do_stuff_with(x);
-- }

-- let Ok(index) | Err(index) = slice.binary_search(&x);

-- for ref a | b in c {}

-- let Ok(x) | Err(x) = binary_search(x);

-- for A | B | C in c {}

-- |(Ok(x) | Err(x))| expr();

-- let ref mut x @ (A | B | C);

-- fn foo((1 | 2 | 3): u8) {}

-- if let x!() | y!() = () {}"#),
--   ("inline const or const blocks as pattern",
--     ppSourceFile (rust
--       fn foo(x: i32) {
--           const CUBE: i32 = 3.pow(3);
--           match x {
--               CUBE => println!("three cubed"),
--               _ => {}
--           }
--       }

--       fn foo(x: i32) {
--           match x {
--               const { 3.pow(3) } => println!("three cubed"),
--               _ => {}
--           }
--       }
--     end),
--     r#"fn foo(x: i32) {
--     const CUBE: i32 = 3.pow(3);
--     match x {
--         CUBE => println!("three cubed"),
--         _ => {}
--     }
-- }

-- fn foo(x: i32) {
--     match x {
--         const { 3.pow(3) } => println!("three cubed"),
--         _ => {}
--     }
-- }"#),
--   ("pattern with turbofish",
--     ppSourceFile (rust
--       match y {
--           None::<T> => 17,
--           _ => 42,
--       }
--     end),
--     r#"match y {
--     None::<T> => 17,
--     _ => 42,
-- }"#)
]
