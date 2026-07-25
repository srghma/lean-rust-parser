macro_rules! check {($ Ty : ty) => {}; (? $ Trait : path) => {compile_error ! ("non-ty") ;}}
check!{? Trait}
fn main() {}
