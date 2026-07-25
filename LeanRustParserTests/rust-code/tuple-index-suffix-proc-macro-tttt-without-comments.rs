extern crate tuple_index_suffix_proc_macro_aux;
use tuple_index_suffix_proc_macro_aux as aux;
fn main() {
  struct TupStruct(i32);
  let tup_struct = TupStruct(42);
  aux::bad_tup_indexing!(0usize);
  aux::bad_tup_struct_indexing!(tup_struct, 0isize);
  aux::bad_tup_indexing!(0u8);
  aux::bad_tup_struct_indexing!(tup_struct, 0u64);
}
