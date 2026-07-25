extern crate unicode_control;
use unicode_control::*;
macro_rules! foo {
  ($x:expr) => {
    $x
  };
}
macro_rules! empty {
  ($x:expr) => {};
}
fn main() {
  let t = vec![1];
  foo!(1);
  empty!(1);
  let x = create_rtl_in_string!();
  forward_stream!(
    mod a {}
  );
  recollect_stream!(
    mod b {}
  );
}
