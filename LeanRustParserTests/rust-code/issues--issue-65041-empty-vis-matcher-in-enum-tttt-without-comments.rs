fn main() {}
macro_rules! mac_variant {
    ($vis:vis MARKER) => {
        enum Enum {
            $vis Unit,
            $vis Tuple(u8, u16),
            $vis Struct { f: u8 },
        }
    }
}
mac_variant!(MARKER);
#[cfg(false)]
enum E {
  U,
  T(u8),
  T { f: String },
}
