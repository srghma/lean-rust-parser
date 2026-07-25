fn main() {
  let _: <<A>::B>::C;
  let _ = <<A>::B>::C;
  let <<A>::B>::C;
  let 0..=<<A>::B>::C;
  <<A>::B>::C;
}
