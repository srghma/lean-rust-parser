fn new<'r, T>() -> &'r T {
  panic!()
}
fn main() {
  let &v = new();
}
