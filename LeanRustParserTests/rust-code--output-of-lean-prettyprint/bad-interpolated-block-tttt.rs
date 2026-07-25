fn main() {}
macro_rules! m {($ b : block) => {'lab : $ b ; unsafe $ b ; | x : u8 | -> () $ b ;}}
fn foo() {
  m!({});
}
