struct Expr<const N: u32>;
trait Trait0 {
  fn required(_: Expr</* error */>);
}
trait Trait1 {
  
}
impl Trait1 for () {
  
}
fn main() {}
