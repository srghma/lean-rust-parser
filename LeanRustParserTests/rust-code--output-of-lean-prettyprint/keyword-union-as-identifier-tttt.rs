#![allow(non_camel_case_types)]
#![allow(non_upper_case_globals)]
mod union {
  
}
mod struct_union {
  
}
mod union_union {
  
}
mod trait_union {
  
}
macro_rules! ty {
  ($ty:ty{
    $($field:ident:$field_ty:ty)*
  }) => {}
}
fn main() {
  let union = union::union();
  let _ = union.union;
  let _ = struct_union::union::union().union;
  let union = union_union::union::union();
  let _ = unsafe { union.union };
  <() as trait_union::union>::union();
  ty!(union{});
  ty!(union{
    union:union
  });
}
