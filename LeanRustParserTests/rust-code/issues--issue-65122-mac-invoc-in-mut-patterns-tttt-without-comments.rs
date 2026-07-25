macro_rules! mac1 {
  ($eval:expr) => {
    let mut $eval = ();
  };
}
macro_rules! mac2 {
  ($eval:pat) => {
    let mut $eval = ();
  };
}
fn foo() {
  mac1! { does_not_exist!() }
  mac2! { does_not_exist!() }
}
fn main() {}
