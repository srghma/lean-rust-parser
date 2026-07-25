fn main() {}
#[cfg(false)]
const _: () = {
  pub trait A {
    const _: () = ();
  }
  impl A for () {
    const _: () = ();
  }
  impl dyn A {
    const _: () = ();
  }
};
