type A = Box<dyn (fn(u8) -> u8) + 'static + Send + Sync>;
fn main() {}
