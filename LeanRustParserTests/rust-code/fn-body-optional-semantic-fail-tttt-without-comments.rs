trait Trait {}
fn main() {
  fn f1();
  fn f1_rpit() -> impl Trait;
  fn f2() {}
  trait X {
    fn f1();
    fn f2() {}
  }
  struct Y;
  impl X for Y {
    fn f1();
    fn f2() {}
  }
  impl Y {
    fn f3();
    fn f4() {}
  }
  extern "C" {
    fn f5();
    fn f6() {}
  }
}
