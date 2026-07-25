fn _f() {
  #[rustfmt::skip]
    let _x = match true {
        true => { 10 },
        false => { return },
    };
}
fn main() {}
