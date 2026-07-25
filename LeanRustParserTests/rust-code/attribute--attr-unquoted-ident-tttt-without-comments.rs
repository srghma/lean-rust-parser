#![allow(unexpected_cfgs)]
fn main() {
  #[cfg(key=foo)]
  println!();
  #[cfg(key = "bar")]
  println!();
  #[cfg(key=foo bar baz)]
  println!();
  #[cfg(key=foo 1 bar 2.0 baz.)]
  println!();
}
macro_rules! make {
  ($name:ident) => {
    #[doc(alias = $name)]
    pub struct S;
  };
}
make!(nickname);
