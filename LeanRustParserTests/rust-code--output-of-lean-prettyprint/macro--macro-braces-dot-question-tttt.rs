use std::io::Write;
fn main() -> Result<(), Error> {
  vec!{
    1, 2, 3
  }.len();
  write!{
    vec![], ""
  }?;
  println!{
    ""
  }[0];
  Ok(())
}
