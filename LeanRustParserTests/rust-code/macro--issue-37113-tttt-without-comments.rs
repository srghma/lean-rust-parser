macro_rules! test_macro {
    ( $( $t:ty ),* $(),*) => {
        enum SomeEnum {
            $( $t, )*
        };
    };
}
fn main() {
  test_macro!(String,);
}
