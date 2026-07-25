fn main() {
  println!("{foo:_1.4}" , foo = 3 . 14);
  println!("{0:_1.4}" , 1 . 11);
  println!("{:_1.4}" , 3 . 14);
  println!("{foo:_1.4" , foo = 3 . 14);
  println!("{0:_1.4" , 1 . 11);
  println!("{:_1.4" , 3 . 14);
  println!("{  0" , 1 . 11);
  println!("{foo:1.4_1.4}" , foo = 3 . 14);
  println!("{0:1.4_1.4}" , 3 . 14);
}
