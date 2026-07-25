use core::ops::{Add, RangeTo};
struct Foo{
  foo: usize
}
impl Foo {
  fn bar(&self) -> usize {
    5
  }
}
impl Add<RangeTo<usize>> for Foo {
  type Output = /* error */;
  fn add(self, range: RangeTo<usize>) -> Output {
    self.foo + range.end
  }
}
fn main() {
  let x = 1 + 3..4 + 5;
  assert_eq!(x,(4..9));
  let x = 1..4 + 5;
  assert_eq!(x,(1..9));
  let x = 1 + 3..4;
  assert_eq!(x,(4..4));
  let a = /* error */;
  let x = a.foo..a.bar();
  assert_eq!(x,(3..5));
  let x = 1 + 3..;
  assert_eq!(x,(4..));
  let x = ..1 + 3;
  assert_eq!(x,(..4));
  let a = &[0, 1, 2, 3, 4, 5, 6];
  let x = &a[1 + 1..2 + 2];
  assert_eq!(x, &a[2..4]);
  let x = &a[..1 + 2];
  assert_eq!(x, &a[..3]);
  let x = &a[1 + 2..];
  assert_eq!(x, &a[3..]);
  /* error */;
  let i = 42;
  /* error */;
  /* error */;
  let x = [1]..[2];
  assert_eq!(x,(([1])..([2])));
  let y = ..;
  assert_eq!(y,(..));
  let reference = &..0;
  assert_eq!(* reference, ..0);
  let reference2 = &&..0;
  assert_eq!(* * reference2, ..0);
  let closure = || ..0;
  assert_eq!(closure(), ..0);
  let sum = /* error */ + ..4;
  assert_eq!(sum, 7);
  macro_rules! expr {
    ($e:expr) => {}
  }
  expr!(!..0);
  expr!(-..0);
  expr!(* ..0);
}
