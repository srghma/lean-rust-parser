fn main() {}
#[cfg(false)]
fn free() {
  fn f(self) {}
  fn f(mut self) {}
  fn f(&self) {}
  fn f(&mut self) {}
  fn f(&'a self) {}
  fn f(&'a mut self) {}
  fn f(self: u8) {}
  fn f(mut self: u8) {}
}
#[cfg(false)]
extern "C" {
  fn f(self);
  fn f(mut self);
  fn f(&self);
  fn f(&mut self);
  fn f(&'a self);
  fn f(&'a mut self);
  fn f(self: u8);
  fn f(mut self: u8);
}
#[cfg(false)]
trait X {
  fn f(self) {}
  fn f(mut self) {}
  fn f(&self) {}
  fn f(&mut self) {}
  fn f(&'a self) {}
  fn f(&'a mut self) {}
  fn f(self: u8) {}
  fn f(mut self: u8) {}
}
#[cfg(false)]
impl X for Y {
  fn f(self) {}
  fn f(mut self) {}
  fn f(&self) {}
  fn f(&mut self) {}
  fn f(&'a self) {}
  fn f(&'a mut self) {}
  fn f(self: u8) {}
  fn f(mut self: u8) {}
}
#[cfg(false)]
impl X for Y {
  type X = /* error */;
  type X = /* error */;
  type X = /* error */;
  type X = /* error */;
  type X = /* error */;
  type X = /* error */;
  type X = /* error */;
  type X = /* error */;
}
