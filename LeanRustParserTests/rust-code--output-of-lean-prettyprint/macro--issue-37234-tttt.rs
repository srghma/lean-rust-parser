macro_rules! failed {() => {{let x = 5 "" ;}}}
fn main() {
  failed!();
}
