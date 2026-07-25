struct S<'a, T> {
  a: &'a T,
  b: &'a T,
}
fn foo<'a, 'b>(start: &'a usize, end: &'a usize) {
  let _x = (*start..*end)
    .map(|x| S { a: start, b: end })
    .collect::<Vec<S<_, 'a>>>();
}
fn main() {}
