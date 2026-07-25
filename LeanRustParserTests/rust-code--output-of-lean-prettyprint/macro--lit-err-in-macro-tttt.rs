macro_rules! f {($ abi : literal) => {extern $ abi fn f () {}}}
f!("Foo" __);
fn main() {}
