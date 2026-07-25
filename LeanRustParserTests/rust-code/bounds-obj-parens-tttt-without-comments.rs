type A = Box<dyn (Fn(u8) -> u8) + 'static + Send + Sync>;
fn main() {}
