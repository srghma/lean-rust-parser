#![feature(const_trait_impl)]
trait Trait {
  fn required();
}
impl Trait for () {
  fn required() {
    pub struct Type;
    impl Type {
      pub fn perform() {}
    }
  }
}
fn main() {}
