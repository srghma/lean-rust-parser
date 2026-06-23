module

public import LeanRustParser.ParserElabForTests

@[expose] public section

def declarationsTests : List (String × String × String) := [
  ("modules",
    ppSourceFile (rust
      mod english;

      mod english {}

      mod english {
          mod greetings {}
          mod farewells {}
      }

      pub mod english;
    end),
    r#"mod english;

mod english {}

mod english {
    mod greetings {}
    mod farewells {}
}

pub mod english;"#),
  ("extern crate declarations",
    ppSourceFile (rust
      extern crate std;
      extern crate std as ruststd;
      pub extern crate futures;
    end),
    r#"extern crate std;
extern crate std as ruststd;
pub extern crate futures;"#),
  ("function declarations",
    ppSourceFile (rust
      fn main() {}

      fn add(x: i32, y: i32) -> i32 {
          return x + y;
      }

      fn takes_slice(slice: &str) {
          println!("Got: {}", slice);
      }

      fn foo() -> [u32; 2] {
          return [1, 2];
      }

      fn foo() -> (u32, u16) {
          return (1, 2);
      }

      fn foo() {
          return
      }

      fn foo(x: impl FnOnce() -> result::Result<T, E>) {}

      fn foo(#[attr] x: i32, #[attr] x: i64) {}

      fn accumulate(self) -> Machine<{State::Accumulate}> {}

      fn foo(bar: impl for<'a> Baz<Quux<'a>>) {}
    end),
    r#"fn main() {}

fn add(x: i32, y: i32) -> i32 {
    return x + y;
}

fn takes_slice(slice: &str) {
    println!("Got: {}", slice);
}

fn foo() -> [u32; 2] {
    return [1, 2];
}

fn foo() -> (u32, u16) {
    return (1, 2);
}

fn foo() {
    return
}

fn foo(x: impl FnOnce() -> result::Result<T, E>) {}

fn foo(#[attr] x: i32, #[attr] x: i64) {}

fn accumulate(self) -> Machine<{State::Accumulate}> {}

fn foo(bar: impl for<'a> Baz<Quux<'a>>) {}"#),
  ("const function declarations",
    ppSourceFile (rust const fn main() {} end),
    "const fn main() {}"),
  ("functions with abstract return types",
    ppSourceFile (rust
      fn triples(a: impl B) -> impl Iterator<Item=(usize)> {
      }
    end),
    r#"fn triples(a: impl B) -> impl Iterator<Item=(usize)> {
}"#),
  ("impl with lifetimes first",
    ppSourceFile (rust fn foo<'a>(x: impl 'a + Clone) {} end),
    "fn foo<'a>(x: impl 'a + Clone) {}"),
  ("functions with precise capture syntax",
    ppSourceFile (rust
      fn capture<T>(&self) -> impl Iterator<Item = usize> + use<'_, T> {
      }
    end),
    r#"fn capture<T>(&self) -> impl Iterator<Item = usize> + use<'_, T> {
}"#),
  ("functions with empty precise capture syntax",
    ppSourceFile (rust
      fn capture(&self) -> impl Iterator<Item = usize> + use<> {
      }
    end),
    r#"fn capture(&self) -> impl Iterator<Item = usize> + use<> {
}"#),
  ("diverging functions",
    ppSourceFile (rust fn aborts() -> ! {} end),
    "fn aborts() -> ! {}"),
  ("extern function declarations",
    ppSourceFile (rust
      extern "C" fn foo() {}
      extern "C" fn printf(
          *const c_char,
          ...,
      ) {}

      pub unsafe extern "C" fn c_variadic_no_use(fmt: *const i8, mut ap: ...) -> i32 {
          // CHECK: call void @llvm.va_start
          vprintf(fmt, ap.as_va_list())
          // CHECK: call void @llvm.va_end
      }
    end),
    r#"extern "C" fn foo() {}
extern "C" fn printf(
    *const c_char,
    ...,
) {}

pub unsafe extern "C" fn c_variadic_no_use(fmt: *const i8, mut ap: ...) -> i32 {
    // CHECK: call void @llvm.va_start
    vprintf(fmt, ap.as_va_list())
    // CHECK: call void @llvm.va_end
}"#),
  ("use declarations",
    ppSourceFile (rust
      use abc;
      use phrases::japanese;
      use sayings::english::greetings;
      use sayings::english::greetings as en_greetings ;
      use phrases::english::{greetings,farewells};
      use sayings::japanese::farewells::*;
      pub use self::greetings::hello;
      use sayings::english::{self, greetings as en_greetings, farewells as en_farewells};
      use three::{ dot::{one, four} };
      use my::{ some::* };
      use my::{*};
      use ::*;
    end),
    r#"use abc;
use phrases::japanese;
use sayings::english::greetings;
use sayings::english::greetings as en_greetings ;
use phrases::english::{greetings,farewells};
use sayings::japanese::farewells::*;
pub use self::greetings::hello;
use sayings::english::{self, greetings as en_greetings, farewells as en_farewells};
use three::{ dot::{one, four} };
use my::{ some::* };
use my::{*};
use ::*;"#),
  ("variable bindings",
    ppSourceFile (rust
      let x;
      let x = 42;
      let x: i32;
      let x: i8 = 42;
      let mut x = 5;
      let y: bool = false;
      let bool: bool = false;
      let u32: str = "";
    end),
    r#"let x;
let x = 42;
let x: i32;
let x: i8 = 42;
let mut x = 5;
let y: bool = false;
let bool: bool = false;
let u32: str = "";"#),
  ("let-else statements",
    ppSourceFile (rust
      let Foo::Bar {
          texts,
          values,
      } = foo().bar().await? else {
          return Err(index)
      };

      let Some(x) = y else {
          let None = z else {
              foo();
              break;
          };
          continue;
      };
    end),
    r#"let Foo::Bar {
    texts,
    values,
} = foo().bar().await? else {
    return Err(index)
};

let Some(x) = y else {
    let None = z else {
        foo();
        break;
    };
    continue;
};"#),
  ("let declarations with if expressions as the value",
    ppSourceFile (rust
      let a = if b {
          c
      } else {
          d
      };
    end),
    r#"let a = if b {
    c
} else {
    d
};"#),
  ("let declarations with contextual keywords as names",
    ppSourceFile (rust
      let default = 1;
      let union = 2;
    end),
    r#"let default = 1;
let union = 2;"#),
  ("structs",
    ppSourceFile (rust
      struct Proton;
      struct Electron {}
      struct Person {pub name: String, pub age: u32}
      struct Point {
        x: i32,

        #[attribute1]
        y: i32,
      }
      struct Color(pub i32, i32, i32);
      struct Inches(i32);
      struct Empty(pub ());
    end),
    r#"struct Proton;
struct Electron {}
struct Person {pub name: String, pub age: u32}
struct Point {
  x: i32,

  #[attribute1]
  y: i32,
}
struct Color(pub i32, i32, i32);
struct Inches(i32);
struct Empty(pub ());"#),
  ("unions",
    ppSourceFile (rust
      pub union in6_addr__bindgen_ty_1 {
          pub __u6_addr8: [__uint8_t; 16usize],
          pub __u6_addr16: [__uint16_t; 8usize],
          pub __u6_addr32: [__uint32_t; 4usize],
          _bindgen_union_align: [u32; 4usize],
      }
    end),
    r#"pub union in6_addr__bindgen_ty_1 {
    pub __u6_addr8: [__uint8_t; 16usize],
    pub __u6_addr16: [__uint16_t; 8usize],
    pub __u6_addr32: [__uint32_t; 4usize],
    _bindgen_union_align: [u32; 4usize],
}"#),
  ("generic structs",
    ppSourceFile (rust
      struct A<B> {}
      struct C<'a, 'b> {}
      struct C<'a,> {}
      struct D<const SIZE: usize> {}
      struct E<#[attr] T> {}
    end),
    r#"struct A<B> {}
struct C<'a, 'b> {}
struct C<'a,> {}
struct D<const SIZE: usize> {}
struct E<#[attr] T> {}"#),
  ("enums",
    ppSourceFile (rust
      pub enum Option<T> {
          None,
          Some(T),
      }

      pub enum Node<T: Item> {
          Internal {
              children: Vec<Tree<T>>,
              height: u16
          },
          #[attribute1]
          #[attribute2]
          Leaf {
              value: T
          }
      }
    end),
    r#"pub enum Option<T> {
    None,
    Some(T),
}

pub enum Node<T: Item> {
    Internal {
        children: Vec<Tree<T>>,
        height: u16
    },
    #[attribute1]
    #[attribute2]
    Leaf {
        value: T
    }
}"#),
  ("enums with values specified",
    ppSourceFile (rust
      pub enum c_style_enum {
          val1 = 1,
          val2 = 2
      }
    end),
    r#"pub enum c_style_enum {
    val1 = 1,
    val2 = 2
}"#),
  ("generic functions",
    ppSourceFile (rust
      pub fn splice<T: Into<Text>>(&mut self, old_range: Range<usize>, new_text: T) {
      }
      pub fn uninit_array<const LEN: usize>() -> [Self; LEN] {}
    end),
    r#"pub fn splice<T: Into<Text>>(&mut self, old_range: Range<usize>, new_text: T) {
}
pub fn uninit_array<const LEN: usize>() -> [Self; LEN] {}"#),
  ("functions with mutable parameters",
    ppSourceFile (rust
      fn foo(mut x : u32) {
      }
    end),
    r#"fn foo(mut x : u32) {
}"#),
  ("functions with destructured parameters",
    ppSourceFile (rust
      fn f1([x, y]: [u32; 2]) {}
      fn f2(&x: &Y) {}
      fn f3((x, y): (T, U)) {}
    end),
    r#"fn f1([x, y]: [u32; 2]) {}
fn f2(&x: &Y) {}
fn f3((x, y): (T, U)) {}"#),
  ("functions with custom types for self",
    ppSourceFile (rust
      trait Callback {
          fn call(self: Box<Self>);
      }
    end),
    r#"trait Callback {
    fn call(self: Box<Self>);
}"#),
  ("constant items",
    ppSourceFile (rust
      const N: i32 = 5;

      trait Foo {
          const X: u8;
      }
    end),
    r#"const N: i32 = 5;

trait Foo {
    const X: u8;
}"#),
  ("static items",
    ppSourceFile (rust
      static N: i32 = 5;
      static mut __progname: *mut ::c_char;
    end),
    r#"static N: i32 = 5;
static mut __progname: *mut ::c_char;"#),
  ("static 'ref' items using lazy_static",
    ppSourceFile (rust static ref ONE: usize = 0; end),
    "static ref ONE: usize = 0;"),
  ("type aliases",
    ppSourceFile (rust
      type Inch = u64;
      type Name<T> = Vec<T>;
      type LazyResolve = impl (FnOnce() -> Capture) + Send + Sync + UnwindSafe;
    end),
    r#"type Inch = u64;
type Name<T> = Vec<T>;
type LazyResolve = impl (FnOnce() -> Capture) + Send + Sync + UnwindSafe;"#),
  ("type alias where clauses",
    ppSourceFile (rust
      type Foo<T> where T: Copy = Box<T>;
      type Assoc3 where = () where;
    end),
    r#"type Foo<T> where T: Copy = Box<T>;
type Assoc3 where = () where;"#),
  ("empty statements",
    ppSourceFile (rust
      fn main() {
          ;
      }
    end),
    r#"fn main() {
    ;
}"#),
  ("attributes",
    ppSourceFile (rust
      #[test]
      fn test_foo() {}

      #[derive(Debug)]
      struct Baz;

      #[derive(Debug, Eq,)]
      struct Foo;

      #[cfg(target_os = "macos")]
      mod macos_only {}

      #![allow(clippy::useless_transmute)]

      #[clippy::cyclomatic_complexity = "100"]
    end),
    r#"#[test]
fn test_foo() {}

#[derive(Debug)]
struct Baz;

#[derive(Debug, Eq,)]
struct Foo;

#[cfg(target_os = "macos")]
mod macos_only {}

#![allow(clippy::useless_transmute)]

#[clippy::cyclomatic_complexity = "100"]"#),
  ("inner attributes",
    ppSourceFile (rust
      mod macos_only {
        #![cfg(target_os = "macos")]
      }

      match ty {
          #![cfg_attr(all(test, exhaustive), deny(non_exhaustive_omitted_patterns))]
          syn::Type::Array(ty) => self.visit_type(&ty.elem),
      }
    end),
    r#"mod macos_only {
  #![cfg(target_os = "macos")]
}

match ty {
    #![cfg_attr(all(test, exhaustive), deny(non_exhaustive_omitted_patterns))]
    syn::Type::Array(ty) => self.visit_type(&ty.elem),
}"#),
  ("key-value attribute expressions",
    ppSourceFile (rust
      #[doc = include_str!("foo-doc.md")]
      fn foo() {}

      #[namespace = foo::bar]
      fn baz() {}
    end),
    r#"#[doc = include_str!("foo-doc.md")]
fn foo() {}

#[namespace = foo::bar]
fn baz() {}"#),
  ("attribute macros",
    ppSourceFile (rust
      foo(#[attr(=> arbitrary tokens <=)] x, y);

      foo(#[bar(some tokens are special in other contexts: $/';()*()+.)] x);
    end),
    r#"foo(#[attr(=> arbitrary tokens <=)] x, y);

foo(#[bar(some tokens are special in other contexts: $/';()*()+.)] x);"#),
  ("derive macro helper attributes",
    ppSourceFile (rust
      // Example from https://github.com/dtolnay/thiserror/blob/21c26903e29cb92ba1a7ff11e82ae2001646b60d/README.md

      use thiserror::Error;

      #[derive(Error, Debug)]
      pub enum Error {
          #[error("first letter must be lowercase but was {:?}", first_char(.0))]
          WrongCase(String),
          #[error("invalid index {idx}, expected at least {} and at most {}", .limits.lo, .limits.hi)]
          OutOfBounds { idx: usize, limits: Limits },
      }
    end),
    r#"// Example from https://github.com/dtolnay/thiserror/blob/21c26903e29cb92ba1a7ff11e82ae2001646b60d/README.md

use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("first letter must be lowercase but was {:?}", first_char(.0))]
    WrongCase(String),
    #[error("invalid index {idx}, expected at least {} and at most {}", .limits.lo, .limits.hi)]
    OutOfBounds { idx: usize, limits: Limits },
}"#),
  ("attributes and expressions",
    ppSourceFile (rust
      fn foo() {
         bar(x,
             #[cfg(foo = "bar")]
             y);
         let z = [#[hello] 2, 7, 8];
         let t = (#[hello] 2, 7, 8);
      }
    end),
    r#"fn foo() {
   bar(x,
       #[cfg(foo = "bar")]
       y);
   let z = [#[hello] 2, 7, 8];
   let t = (#[hello] 2, 7, 8);
}"#),
  ("inherent impls",
    ppSourceFile (rust
      impl Person {
        const leg_count : u32 = 2;

        fn walk(self) {}
        fn walk_mut(mut self) {}
        fn talk(& self) {}
        fn talk_mut(&'a mut self) {}
      }

      impl Machine<{State::Init}> {}
    end),
    r#"impl Person {
  const leg_count : u32 = 2;

  fn walk(self) {}
  fn walk_mut(mut self) {}
  fn talk(& self) {}
  fn talk_mut(&'a mut self) {}
}

impl Machine<{State::Init}> {}"#),
  ("trait impls",
    ppSourceFile (rust
      impl<'a> iter::Iterator for Self::Iter<'a> {
      }

      impl ConvertTo<i64> for i32 {
          fn convert(&self) -> i64 { *self as i64 }
      }
    end),
    r#"impl<'a> iter::Iterator for Self::Iter<'a> {
}

impl ConvertTo<i64> for i32 {
    fn convert(&self) -> i64 { *self as i64 }
}"#),
  ("unsafe impls",
    ppSourceFile (rust
      unsafe impl Foo {
      }
    end),
    r#"unsafe impl Foo {
}"#),
  ("disable automatically derived trait impls",
    ppSourceFile (rust impl !Send for Foo {} end),
    "impl !Send for Foo {}"),
  ("impl dyn with parentheses",
    ppSourceFile (rust
      pub unsafe trait Trait {}

      unsafe impl Trait for dyn (::std::any::Any) + Send { }
    end),
    r#"pub unsafe trait Trait {}

unsafe impl Trait for dyn (::std::any::Any) + Send { }"#),
  ("trait impl signature",
    ppSourceFile (rust
      impl<K: Debug + Ord> Debug for OccupiedError<K>;
      impl<K: Debug + Ord> Display for OccupiedError<K>;
    end),
    r#"impl<K: Debug + Ord> Debug for OccupiedError<K>;
impl<K: Debug + Ord> Display for OccupiedError<K>;"#),
  ("impls with default functions",
    ppSourceFile (rust
      impl Foo {
        const default fn bar() -> i32 {
          // Make 'default' still works as an identifier
          default.bar();
        }
      }
    end),
    r#"impl Foo {
  const default fn bar() -> i32 {
    // Make 'default' still works as an identifier
    default.bar();
  }
}"#),
  ("trait declarations",
    ppSourceFile (rust
      pub trait Item: Clone + Eq + fmt::Debug {
          fn summarize(&self) -> Self::Summary;
      }

      unsafe trait Foo { }
    end),
    r#"pub trait Item: Clone + Eq + fmt::Debug {
    fn summarize(&self) -> Self::Summary;
}

unsafe trait Foo { }"#),
  ("trait declarations with optional type parameters",
    ppSourceFile (rust
      trait Add<RHS=Self> {
          type Output;
          fn add(self, rhs: RHS) -> Self::Output;
      }
    end),
    r#"trait Add<RHS=Self> {
    type Output;
    fn add(self, rhs: RHS) -> Self::Output;
}"#),
  ("unsized types in trait bounds",
    ppSourceFile (rust
      trait Foo<T: ?Sized> {
      }

      fn univariant(this: &impl ?Sized, that: &(impl LayoutCalculator + ?Sized)) {}
    end),
    r#"trait Foo<T: ?Sized> {
}

fn univariant(this: &impl ?Sized, that: &(impl LayoutCalculator + ?Sized)) {}"#),
  ("trait bounds in type arguments in trait",
    ppSourceFile (rust impl<T: AstDeref<Target: HasNodeId>> HasNodeId for T {} end),
    "impl<T: AstDeref<Target: HasNodeId>> HasNodeId for T {}"),
  ("macro invocations inside trait declarations",
    ppSourceFile (rust
      pub trait A: B + C + D {
          private_decl!{}
          fn f(&self);
      }
    end),
    r#"pub trait A: B + C + D {
    private_decl!{}
    fn f(&self);
}"#),
  ("associated types",
    ppSourceFile (rust
      pub trait Graph {
          type N: fmt::Display;
          type E;
      }
    end),
    r#"pub trait Graph {
    type N: fmt::Display;
    type E;
}"#),
  ("associated type definitions",
    ppSourceFile (rust
      impl Trait for T {
          type Associated = T where 'static: 'static;
      }
    end),
    r#"impl Trait for T {
    type Associated = T where 'static: 'static;
}"#),
  ("generic associated types",
    ppSourceFile (rust
      pub trait Database {
          type F<'a, D>: Future<Output = D> + 'a;
      }

      impl Database for Foo {
          type F<'a, D> = DatabaseFuture<'a, D>;
      }

      fn use_database1<D: Database<F<'a, TD> = F>>() {}

      fn use_database2<D>()
      where
          D: Database<F<'a, TD> = F>,
      {}
    end),
    r#"pub trait Database {
    type F<'a, D>: Future<Output = D> + 'a;
}

impl Database for Foo {
    type F<'a, D> = DatabaseFuture<'a, D>;
}

fn use_database1<D: Database<F<'a, TD> = F>>() {}

fn use_database2<D>()
where
    D: Database<F<'a, TD> = F>,
{}"#),
  ("higher-ranked types",
    ppSourceFile (rust
      trait T: for<'a> AddAssign<&'a usize> {
      }

      type FnObject<'b> = dyn for<'a> FnLike<&'a isize, &'a isize> + 'b;
    end),
    r#"trait T: for<'a> AddAssign<&'a usize> {
}

type FnObject<'b> = dyn for<'a> FnLike<&'a isize, &'a isize> + 'b;"#),
  ("visibility modifiers",
    ppSourceFile (rust
      pub fn a() {}
      pub(super) fn b() {}
      pub(self) fn c() {}
      pub(crate) fn c() {}
      pub(in crate::d) fn e() {}
    end),
    r#"pub fn a() {}
pub(super) fn b() {}
pub(self) fn c() {}
pub(crate) fn c() {}
pub(in crate::d) fn e() {}"#),
  ("function parameter names that match built-in type names",
    ppSourceFile (rust
      fn foo(str: *const c_char) {}
      fn bar(bool: bool) {}
    end),
    r#"fn foo(str: *const c_char) {}
fn bar(bool: bool) {}"#),
  ("where clauses",
    ppSourceFile (rust
      fn walk<F>(&self, it: &mut F) -> bool
          where F: FnMut(&Pat) -> bool
      {
        return false
      }

      impl<'a, T: 'a + Item> Iterator for Iter<'a, T> where Self: 'a {
      }

      impl<T> A for B<T>
          where C<T>: D,
                T: 'c,
                'c: 'b,
      {
      }

      impl<'a, E> Read
      where &'a E: Read,
      {
      }

      impl<T> A for B<T> where (T, T, T): C, {}

      impl<T> A for B<T>
          where for<'a> D<T>: E<'a>,
      {
      }

      pub trait A<B> where B: C,
      {
      }

      fn foo<A>() where A: B + As<f64>, f64: As<A> {}

      impl<A> Default for B<A> where *mut A: C + D {}
    end),
    r#"fn walk<F>(&self, it: &mut F) -> bool
    where F: FnMut(&Pat) -> bool
{
  return false
}

impl<'a, T: 'a + Item> Iterator for Iter<'a, T> where Self: 'a {
}

impl<T> A for B<T>
    where C<T>: D,
          T: 'c,
          'c: 'b,
{
}

impl<'a, E> Read
where &'a E: Read,
{
}

impl<T> A for B<T> where (T, T, T): C, {}

impl<T> A for B<T>
    where for<'a> D<T>: E<'a>,
{
}

pub trait A<B> where B: C,
{
}

fn foo<A>() where A: B + As<f64>, f64: As<A> {}

impl<A> Default for B<A> where *mut A: C + D {}"#),
  ("external modules",
    ppSourceFile (rust
      extern {
        pub fn napi_module_register(mod_: *mut napi_module);
      }

      extern "C" {}

      unsafe extern "C" {}
    end),
    r#"extern {
  pub fn napi_module_register(mod_: *mut napi_module);
}

extern "C" {}

unsafe extern "C" {}"#),
  ("crate visibility",
    ppSourceFile (rust
      crate mod foo;
      crate struct Foo(crate crate::Bar);
      crate fn foo() { }
      crate const X: u32 = 0;
    end),
    r#"crate mod foo;
crate struct Foo(crate crate::Bar);
crate fn foo() { }
crate const X: u32 = 0;"#),
  ("reserved keywords in path",
    ppSourceFile (rust
      struct A {
        a: default::B,
        b: union::C,
      }
    end),
    r#"struct A {
  a: default::B,
  b: union::C,
}"#),
  ("array constraint in where clause",
    ppSourceFile (rust
      fn foo<D>(val: D)
      where
          [u8; 32]: From<D>,

      {}
    end),
    r#"fn foo<D>(val: D)
where
    [u8; 32]: From<D>,

{}"#),
  ("const generics with default",
    ppSourceFile (rust pub struct Loaf<T: Sized, const N: usize = 1>([T; N]); end),
    "pub struct Loaf<T: Sized, const N: usize = 1>([T; N]);")
]
