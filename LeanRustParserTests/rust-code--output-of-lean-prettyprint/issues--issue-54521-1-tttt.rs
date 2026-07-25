struct X{
  len: u32
}
fn main() {
  let x = X { len: 3 };
  let _ = x.len > (3);
  let _ = x.len >> (3);
}
