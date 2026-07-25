fn foo() -> Option<fn() -> Option<bool>> {
  Some(|| Some(true))
}
fn main() {}
