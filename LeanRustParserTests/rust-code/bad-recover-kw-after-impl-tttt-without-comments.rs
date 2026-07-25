macro_rules! impl_primitive {
  ($ty:ty) => {
    compile_error!("whoops");
  };
  (impl async) => {};
}
impl_primitive!(impl async);
fn main() {}
