macro_rules! mac {
  ($attr_item: meta) => {
    #[cfg($attr_item)]
    struct S;
  };
}
mac!(an(arbitrary token stream));
#[cfg(feature = -1)]
fn handler() {}
fn main() {}
