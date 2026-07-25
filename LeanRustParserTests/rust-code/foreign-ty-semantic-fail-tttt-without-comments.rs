#![feature(extern_types)]
fn main() {}
extern "C" {
  type A: Ord;
  type B<'a>
  where
    'a: 'static;
  type C<T: Ord>
  where
    T: 'static;
  type D = u8;
  type E;
}
