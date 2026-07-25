macro_rules! foo {
    { $+ } => {
        $(x)(y)
    }
}
foo!();
fn main() {}
