fn main() {
  let a: usize = 0;
  let long_name: usize = 0;
  println!("{}", a as usize > long_name);
  println!("{}", a as usize < long_name);
  println!("{}{}", a as usize < long_name, long_name);
  println!("{}", a as usize < 4);
  println!("{}", a
                   as
                   usize
                   <
                   4);
  println!("{}", a
                   as
                   usize
                   <
                   5);
  println!("{}", a as usize << long_name);
}
