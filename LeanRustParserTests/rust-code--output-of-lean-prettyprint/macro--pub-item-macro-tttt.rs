macro_rules! priv_x {() => {static x : u32 = 0 ;}}
macro_rules! pub_x {() => {pub priv_x ! () ;}}
mod foo {
  pub_x!();
}
fn main() {
  let y: u32 = foo::x;
}
