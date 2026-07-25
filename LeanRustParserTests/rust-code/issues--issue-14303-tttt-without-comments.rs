enum Enum<'a, T, 'b> {
  A(&'a &'b T),
}
struct Struct<'a, T, 'b> {
  x: &'a &'b T,
}
trait Trait<'a, T, 'b> {}
fn foo<'a, T, 'b>(x: &'a T) {}
struct Y<T>(T);
impl<'a, T, 'b> Y<T> {}
mod bar {
  pub struct X<'a, 'b, 'c, T> {
    a: &'a str,
    b: &'b str,
    c: &'c str,
    t: T,
  }
}
fn bar<'a, 'b, 'c, T>(x: bar::X<'a, T, 'b, 'c>) {}
fn main() {}
