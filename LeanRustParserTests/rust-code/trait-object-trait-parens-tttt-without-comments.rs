trait Trait<'a> {}
trait Obj {}
fn f<T: (Copy) + (?Sized) + (for<'a> Trait<'a>)>() {}
fn main() {
  let _: Box<(Obj) + (?Sized) + (for<'a> Trait<'a>)>;
  let _: Box<?Sized + (for<'a> Trait<'a>) + (Obj)>;
  let _: Box<for<'a> Trait<'a> + (Obj) + (?Sized)>;
}
