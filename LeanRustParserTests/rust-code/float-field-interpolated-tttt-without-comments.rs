struct S(u8, (u8, u8));
macro_rules! generate_field_accesses {
  ($a:tt, $b:literal, $c:expr) => {
    let s = S(0, (0, 0));
    s.$a;
    {
      s.$b;
    }
    {
      s.$c;
    }
  };
}
fn main() {
  generate_field_accesses!(1.1, 1.1, 1.1);
}
