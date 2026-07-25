macro_rules! foo {
  () => {
    break();
  };
  ($e:expr) => {
    break $e;
  };
  (stmt $s:stmt) => {
    $s
  };
  (@ $e:expr) => {{
    break $e;
  }};
  (=> $s:stmt) => {{
    $s
  }}
}
fn main() {
  { foo!(); }
  { foo!(()); }
  { foo!(stmt break()); }
  { foo!(@()); }
  { foo!(=>break()); }
  { macro_rules! bar {
    () => {
      break()
    }
  } bar!() }
}
