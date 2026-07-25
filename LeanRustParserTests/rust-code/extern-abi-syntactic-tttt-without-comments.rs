fn main() {}
#[cfg(false)]
extern "some_abi_that_we_are_sure_does_not_exist_semantically" fn foo() {}
#[cfg(false)]
extern "some_abi_that_we_are_sure_does_not_exist_semantically" {
  fn foo();
}
#[cfg(false)]
type T = extern "some_abi_that_we_are_sure_does_not_exist_semantically" fn();
