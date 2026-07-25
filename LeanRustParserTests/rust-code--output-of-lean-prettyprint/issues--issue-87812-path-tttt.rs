macro_rules! foo {
  ( $f:path) => {{
    let _:usize = $f;
  }}
}
struct Baz;
fn main() {
  foo!(Baz);
}
