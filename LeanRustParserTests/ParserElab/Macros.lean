module

public import LeanRustParser.ParserElabForTests

@[expose] public section

def macrosTests : List (String × String × String) := [
--   ("macro invocation - no arguments",
--     ppSourceFile (rust
--       a!();
--       b![];
--       c!{};
--       d::e!();
--       f::g::h!{};
--     end),
--     r#"a!();
-- b![];
-- c!{};
-- d::e!();
-- f::g::h!{};"#),
--   ("macro invocation - arbitrary tokens",
--     ppSourceFile (rust
--       a!(* a *);
--       a!(& a &);
--       a!(- a -);
--       a!(b + c + +);
--       a!('a'..='z');
--       a!('\u{0}'..='\u{2}');
--       a!('lifetime)
--       default!(a);
--       union!(a);
--       a!($);
--       a!($());
--       a!($ a $);
--       a!(${$([ a ])});
--       a!($a $a:ident $($a);*);
--     end),
--     r#"a!(* a *);
-- a!(& a &);
-- a!(- a -);
-- a!(b + c + +);
-- a!('a'..='z');
-- a!('\\u{0}'..='\\u{2}');
-- a!('lifetime)
-- default!(a);
-- union!(a);
-- a!($);
-- a!($());
-- a!($ a $);
-- a!(${$([ a ])});
-- a!($a $a:ident $($a);*);"#),
--   ("macro invocation with comments",
--     ppSourceFile (rust
--       ok! {
--         // one
--         /* two */
--       }
--     end),
--     r#"ok! {
--   // one
--   /* two */
-- }"#),
--   ("macro definition",
--     ppSourceFile (rust
--       macro_rules! say_hello {
--           () => (
--               println!("Hello!");
--           )
--       }

--       macro_rules! four {
--           () => {1 + 3};
--       }

--       macro_rules! foo {
--           (x => $e:expr) => (println!("mode X: {}", $e));
--           (y => $e:expr) => (println!("mode Y: {}", $e))
--       }

--       macro_rules! o_O {
--           (
--             $($x:expr; [ $( $y:expr ),* ]);*
--           ) => {
--             $($($x + $e),*),*
--           }
--       }

--       macro_rules! zero_or_one {
--           ($($e:expr),?) => {
--               $($e),?
--           };
--       }

--       macro_rules! empty [
--           () => {};
--       ];
--     end),
--     r#"macro_rules! say_hello {
--     () => (
--         println!("Hello!");
--     )
-- }

-- macro_rules! four {
--     () => {1 + 3};
-- }

-- macro_rules! foo {
--     (x => $e:expr) => (println!("mode X: {}", $e));
--     (y => $e:expr) => (println!("mode Y: {}", $e))
-- }

-- macro_rules! o_O {
--     (
--       $($x:expr; [ $( $y:expr ),* ]);*
--     ) => {
--       $($($x + $e),*),*
--     }
-- }

-- macro_rules! zero_or_one {
--     ($($e:expr),?) => {
--         $($e),?
--     };
-- }

-- macro_rules! empty [
--     () => {};
-- ];"#)
]
