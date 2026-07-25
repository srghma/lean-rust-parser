#![allow(unused_braces, unused_unsafe)]
macro_rules! unit {
  () => {{
    ()
  }}
}
#[derive(Copy, Clone)]
struct X;
fn main() {
  let x = X;
  let _: fn(X) -> X = { if true {}; |x| x };
  let _: fn(X) -> X = { if true {} else {}; |x| x };
  let _: fn(X) -> X = { /* error */; |x| x };
  let _: fn(X) -> X = { { () }; |x| x };
  let _: fn(X) -> X = { unsafe {}; |x| x };
  let _: fn(X) -> X = { /* error */; |x| x };
  let _: fn(X) -> X = { /* error */; |x| x };
  let _: fn(X) -> X = { /* error */; |x| x };
  let _: fn(X) -> X = { const {}; |x| x };
  let _: fn(X) -> X = { unit!{}; |x| x };
  () = { ""; |x| x };
  () = { (""); |x| x };
  () = { [""]; |x| x };
  () = { unit!(); |x| x };
  () = { unit![]; |x| x };
  () = /* error */;
  macro_rules! assert_statement_boundary {
    ($expr:expr) => {
      let _: fn(X) -> X ={
        $expr | x| x
      };() =match X{
        X if false => $expr | X if false =>{}X =>{}
      };
    }
  }
  macro_rules! assert_no_statement_boundary {
    ($expr:expr) => {
      () ={
        $expr | x| x
      };() =match x{
        X if false => $expr | X, X =>{}
      };
    }
  }
  assert_statement_boundary!(if true{});
  assert_no_statement_boundary!("");
}
impl BitOr<X> for () {
  type Output = /* error */;
  fn bitor(self, _: X) {}
}
impl BitOr<X> for &str {
  type Output = /* error */;
  fn bitor(self, _: X) {}
}
impl {}
