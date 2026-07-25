fn main() {}
extern "\x43" fn foo() {}
extern "\x43" {
  fn bar();
}
type T = extern "\x43" fn();
