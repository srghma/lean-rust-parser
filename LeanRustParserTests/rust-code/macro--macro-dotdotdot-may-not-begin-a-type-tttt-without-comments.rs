macro_rules! ck {
  ($ty:ty) => {
    compile_error!("");
  };
  (...) => {};
}
ck!(...);
fn main() {}
