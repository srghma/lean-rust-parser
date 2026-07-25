fn foo(a: Option<u32>, b: Option<u32>) -> bool {
  if let Some(x) = a {
    true
  } else {
    false
  }
  &&if let Some(y) = a { true } else { false }
}
fn bar() -> bool {
  false
}
fn main() {
  if true {
    true
  } else {
    false
  }
  &&true;
  if true {
    true
  } else {
    false
  }
  &&if true { true } else { false };
  if true {
    true
  } else {
    false
  }
  if true {
    true
  } else {
    false
  };
  if true {
    bar()
  } else {
    bar()
  }
  &&if true { bar() } else { bar() };
  if true {
    bar()
  } else {
    bar()
  }
  if true {
    bar()
  } else {
    bar()
  };
  let _ = if true { true } else { false } && true;
}
