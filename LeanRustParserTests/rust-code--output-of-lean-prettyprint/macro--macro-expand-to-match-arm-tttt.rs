macro_rules! arm {
  ($pattern:pat => $block:block) => {
    $pattern => $block
  }
}
fn main() {
  let x = Some(1);
  /* error */;
}
