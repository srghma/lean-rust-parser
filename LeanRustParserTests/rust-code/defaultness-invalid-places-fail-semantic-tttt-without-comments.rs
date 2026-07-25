#![feature(specialization)]
fn main() {}
trait X {
  default const A: u8;
  default const B: u8 = 0;
  type D;
  type C: Ord;
  default fn f1();
  default fn f2() {}
}
default const E: u8 = 0;
type F = ();
default fn h() {}
