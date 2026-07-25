macro_rules! m {
  (($expr:expr ; )) => {
    $expr
  };
}
fn main() {
  let x = m!(( ||() ; ));
}
