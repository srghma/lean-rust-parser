#![feature(c_variadic)]
#![allow(anonymous_parameters)]
fn main() {}
fn f1_1(x: isize, _: ...) {}
fn f1_2(_: ...) {}
unsafe extern "Rust" fn f1_3(_: ...) {}
extern "C" fn f2_1(x: isize, _: ...) {}
extern "C" fn f2_2(_: ...) {}
extern "C" fn f2_3(_: ..., x: isize) {}
extern "C" fn f3_1(x: isize, _: ...) {}
extern "C" fn f3_2(_: ...) {}
extern "C" fn f3_3(_: ..., x: isize) {}
const unsafe extern "C" fn f4_1(x: isize, _: ...) {}
const extern "C" fn f4_2(x: isize, _: ...) {}
const extern "C" fn f4_3(_: ..., x: isize, _: ...) {}
extern "C" {
  fn e_f2(..., x: isize);
}
struct X;
impl X {
  fn i_f1(x: isize, _: ...) {}
  fn i_f2(_: ...) {}
  fn i_f3(_: ..., x: isize, _: ...) {}
  fn i_f4(_: ..., x: isize, _: ...) {}
  const fn i_f5(x: isize, _: ...) {}
}
trait T {
  fn t_f1(x: isize, _: ...) {}
  fn t_f2(x: isize, _: ...);
  fn t_f3(_: ...) {}
  fn t_f4(_: ...);
  fn t_f5(_: ..., x: isize) {}
  fn t_f6(_: ..., x: isize);
}
