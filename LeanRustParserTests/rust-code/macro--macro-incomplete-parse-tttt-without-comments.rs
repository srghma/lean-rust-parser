macro_rules! ignored_item {
    () => {
        fn foo() {}
        fn bar() {}
        ,
    }
}
macro_rules! ignored_expr {
    () => ( 1,
            2 )
}
macro_rules! ignored_pat {
    () => ( 1, 2 )
}
ignored_item!();
fn main() {
  ignored_expr!();
  match 1 {
    ignored_pat!() => (),
    _ => (),
  }
}
