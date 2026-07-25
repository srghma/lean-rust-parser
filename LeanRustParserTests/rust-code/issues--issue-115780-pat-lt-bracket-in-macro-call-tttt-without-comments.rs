macro_rules! mdo {
    ($p: pat =<< $e: expr ; $( $t: tt )*) => {
        $e.and_then(|$p| mdo! { $( $t )* })
    };
    (ret<$ty: ty> $e: expr;) => { Some::<$ty>($e) };
}
fn main() {
  mdo! {
      x_val =<< Some(0);
      y_val =<< Some(1);
      ret<(i32, i32)> (x_val, y_val);
  };
}
