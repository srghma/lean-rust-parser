#[path = "not_a_real_file.rs"]
mod m;
fn main() {
  assert_eq!(m::foo(), 10);
}
