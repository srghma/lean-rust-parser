trait Trait<T> {
  type Item;
}
pub fn test<W, I: Trait<Item = (), W>>() {}
fn main() {}
