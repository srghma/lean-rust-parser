macro_rules! test_expr {($ expr : expr) => {};}
macro_rules! test_ty {($ a : ty | $ b : ty) => {};}
fn main() {
  test_expr!(a as fn () -> B | C);
  test_expr!(| _ : fn () -> B | C | D);
  test_ty!(A | B);
  test_ty!(fn () -> A | B);
  test_ty!(impl Fn () -> A | B);
}
