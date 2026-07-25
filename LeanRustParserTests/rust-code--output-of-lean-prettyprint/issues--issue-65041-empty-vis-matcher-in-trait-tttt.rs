fn main() {}
macro_rules! mac_in_trait {
  ($vis:vis MARKER) => {
    $vis fn beta(){} $vis const GAMMA:u8; $vis type Delta;
  }
}
trait Alpha {
  mac_in_trait!(MARKER);
}
#[cfg(false)]
trait Foo {
  pub fn bar();
  type baz;
  const QUUX: u8;
}
