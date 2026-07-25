fn main() {}
struct X;
impl X {
  type Y;
  type Z: Ord;
  type W: Ord
  where
    Self: Eq;
  type W
  where
    Self: Eq;
}
