fn main() {}
trait X {
  fn foo();
}
impl X for () {
  fn foo() {
    struct S;
    impl S {
      pub const X: u8 = 0;
      pub fn bar() {}
      async fn qux() {}
    }
  }
}
