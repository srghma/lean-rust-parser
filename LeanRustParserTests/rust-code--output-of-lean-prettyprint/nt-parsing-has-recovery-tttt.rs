macro_rules! foo {($ e : expr) => {};}
foo!(1 + @);
foo!(1 + @);
fn main() {
  let _recovery_witness: () = 0;
}
