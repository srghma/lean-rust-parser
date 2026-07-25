#![feature(const_trait_impl)]
const trait Trait {
  fn required();
}
const impl Trait for () {
  fn required() {
    pub struct Type;
    impl Type {
      pub fn perform() {}
    }
  }
}
fn main() {}
