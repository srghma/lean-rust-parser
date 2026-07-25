fn main() {}
fn free() {
  fn f1(self) {}
  fn f2(mut self) {}
  fn f3(&self) {}
  fn f4(&mut self) {}
  fn f5<'a>(&'a self) {}
  fn f6<'a>(&'a mut self) {}
  fn f7(self: u8) {}
  fn f8(mut self: u8) {}
}
extern "C" {
  fn f1(self);
  fn f2(mut self);
  fn f3(&self);
  fn f4(&mut self);
  fn f5<'a>(&'a self);
  fn f6<'a>(&'a mut self);
  fn f7(self: u8);
  fn f8(mut self: u8);
}
type X1 = fn(self);
type X2 = fn(mut self);
type X3 = fn(&self);
type X4 = fn(&mut self);
type X5 = for<'a> fn(&'a self);
type X6 = for<'a> fn(&'a mut self);
type X7 = fn(self: u8);
type X8 = fn(mut self: u8);
