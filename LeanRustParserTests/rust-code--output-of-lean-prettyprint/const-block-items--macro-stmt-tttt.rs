#![feature(const_block_items)]
macro_rules! foo {($ item : item) => {$ item}}
fn main() {
  foo!(const {});
}
