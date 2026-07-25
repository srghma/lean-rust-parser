macro_rules! bah {
  ($a:expr) => {
    $a
  };
}
trait Bar {
  bah!(2);
}
fn main() {
  let _recovery_witness: () = 0;
}
