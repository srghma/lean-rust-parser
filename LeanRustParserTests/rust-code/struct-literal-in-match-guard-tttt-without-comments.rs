#[derive(PartialEq)]
struct Foo {
  x: isize,
}
fn foo(f: Foo) {
  match () {
    () if f == Foo { x: 42 } => {}
    () if let Foo { x: 0.. } = Foo { x: 42 } => {}
    _ => {}
  }
}
fn main() {}
