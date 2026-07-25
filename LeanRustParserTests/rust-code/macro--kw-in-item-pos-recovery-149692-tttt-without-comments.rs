macro_rules! m {
  ($id:item()) => {};
}
m!(Self());
m!(Self {});
m!(crate());
fn main() {}
