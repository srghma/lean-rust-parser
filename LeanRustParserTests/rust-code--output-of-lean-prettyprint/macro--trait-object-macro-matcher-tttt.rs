macro_rules! m {($ t : ty) => {let _ : $ t ;}}
fn main() {
  m!('static);
}
