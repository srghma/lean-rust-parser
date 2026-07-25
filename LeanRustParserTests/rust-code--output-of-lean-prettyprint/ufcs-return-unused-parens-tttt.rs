#![allow(dead_code)]
#![warn(unused_parens)]
fn with_parens<T: ToString>(arg: T) -> String {
  return (<T as ToString>::to_string(&arg));
}
fn no_parens<T: ToString>(arg: T) -> String {
  return <T as ToString>::to_string(&arg);
}
fn main() {}
