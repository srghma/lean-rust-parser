mod not_a_real_file;
fn main() {
  assert_eq!(mod_file_aux::bar(), 10);
}
