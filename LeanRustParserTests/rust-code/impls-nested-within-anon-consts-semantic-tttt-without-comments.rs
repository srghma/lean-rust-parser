struct Expr<const N: u32>;
trait Trait0 {
  fn required(
    _: Expr<
      {
        struct Type;
        impl Type {
          pub fn perform() {}
        }
        0
      },
    >,
  );
}
trait Trait1 {}
impl Trait1 for () where
  [(); {
    struct Type;
    impl Type {
      pub const STORE: Self = Self;
    }
    0
  }]:
{
}
fn main() {}
