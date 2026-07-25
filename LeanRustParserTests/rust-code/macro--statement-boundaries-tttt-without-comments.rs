#![allow(unused_braces, unused_unsafe)]
macro_rules! unit {
  () => {{ () }};
}
#[derive(Copy, Clone)]
struct X;
fn main() {
  let x = X;
  let _: fn(X) -> X = {
    if true {}
    |x| x
  };
  let _: fn(X) -> X = {
    if true {
    } else {
    }
    |x| x
  };
  let _: fn(X) -> X = {
    match () {
      () => {}
    }
    |x| x
  };
  let _: fn(X) -> X = {
    {
      ()
    }
    |x| x
  };
  let _: fn(X) -> X = {
    unsafe {}
    |x| x
  };
  let _: fn(X) -> X = {
    while false {}
    |x| x
  };
  let _: fn(X) -> X = {
    loop {
      break;
    }
    |x| x
  };
  let _: fn(X) -> X = {
    for _ in 0..0 {}
    |x| x
  };
  let _: fn(X) -> X = {
    const {}
    |x| x
  };
  let _: fn(X) -> X = {
    unit! {}
    |x| x
  };
  () = { "" | x | x };
  () = { ("") | x | x };
  () = { [""] | x | x };
  () = { unit!() | x | x };
  () = { unit![] | x | x };
  () = match x {
    X if false => if true {},
    X if false => {}
    X if false => {
      if true {
      } else {
      }
    }
    X if false => {}
    X if false => match () {
      () => {}
    },
    X if false => {}
    X if false => (),
    X if false => {}
    X if false => unsafe {},
    X if false => {}
    X if false => while false {},
    X if false => {}
    X if false => loop {
      break;
    },
    X if false => {}
    X if false => for _ in 0..0 {},
    X if false => {}
    X if false => const {},
    X if false => {}
    X if false => "" | X,
    X if false => ("") | X,
    X if false => [""] | X,
    X if false => unit! {} | X,
    X if false => unit!() | X,
    X if false => unit![] | X,
    X => {}
  };
  macro_rules! assert_statement_boundary {
        ($expr:expr) => {
            let _: fn(X) -> X = { $expr |x| x };
            () = match X {
                X if false => $expr | X if false => {}
                X => {}
            };
        };
    }
  macro_rules! assert_no_statement_boundary {
    ($expr:expr) => {
      () = { $expr | x | x };
      () = match x {
        X if false => $expr | X,
        X => {}
      };
    };
  }
  assert_statement_boundary!(if true {});
  assert_no_statement_boundary!("");
}
impl std::ops::BitOr<X> for () {
  type Output = ();
  fn bitor(self, _: X) {}
}
impl std::ops::BitOr<X> for &str {
  type Output = ();
  fn bitor(self, _: X) {}
}
impl<T, const N: usize> std::ops::BitOr<X> for [T; N] {
  type Output = ();
  fn bitor(self, _: X) {}
}
