enum Enum<'a, T, 'b> {
  A(&&T)
}
struct Struct<'a, T, 'b>{
  x: &&T
}
trait Trait<'a, T, 'b> {
  
}
fn foo<'a, T, 'b>(x: &T) {}
struct Y<T>(T);
impl Y<T> {
  
}
mod bar {
  
}
fn bar<'a, 'b, 'c, T>(x: X</* error */, T, /* error */, /* error */>) {}
fn main() {}
