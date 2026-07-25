fn main() {}
extern "C" fn foo() {}
extern "C" {
  fn bar();
}
type T = extern "C" fn();
