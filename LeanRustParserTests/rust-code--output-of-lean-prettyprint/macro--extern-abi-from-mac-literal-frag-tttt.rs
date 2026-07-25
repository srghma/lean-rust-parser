#![allow(clashing_extern_declarations)]
fn main() {}
macro_rules! abi_from_lit_frag {($ abi : literal) => {extern $ abi {fn _import () ;} unsafe extern $ abi {} extern $ abi fn _export () {} type _PTR = extern $ abi fn () ;}}
macro_rules! abi_from_expr_frag {($ abi : expr) => {extern $ abi {fn _import () ;} unsafe extern $ abi {} extern $ abi fn _export () {} type _PTR = extern $ abi fn () ;}}
mod rust {
  abi_from_lit_frag!("Rust");
}
mod c {
  abi_from_lit_frag!("C");
}
mod rust_expr {
  abi_from_expr_frag!("Rust");
}
mod c_expr {
  abi_from_expr_frag!("C");
}
