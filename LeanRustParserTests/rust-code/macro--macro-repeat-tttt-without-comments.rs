macro_rules! mac {
  ( $($v:tt)* ) => {
    $v
  };
}
fn main() {
  mac!(0);
  mac!(1);
}
