#[allow(unused_macro_rules)]
macro_rules! m {
  ($e:expr) => {
    0
  };
  ($e:expr,) => {
    1
  };
  (do yeet $e:expr, foo) => {
    2
  };
}
fn main() {
  assert_eq!(2, m!(do yeet 42, foo));
}
