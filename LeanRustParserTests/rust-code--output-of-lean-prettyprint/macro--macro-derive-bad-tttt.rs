#![crate_type = "lib"]
#![feature(macro_derive)]
macro_rules! derive_incomplete_1 {derive}
macro_rules! derive_incomplete_2 {derive ()}
macro_rules! derive_incomplete_3 {derive () {}}
macro_rules! derive_incomplete_4 {derive () {} =>}
macro_rules! derive_noparens_1 {derive {} {} => {}}
macro_rules! derive_noparens_2 {derive [] {} => {}}
macro_rules! derive_noparens_3 {derive _ {} => {}}
macro_rules! derive_args_1 {derive ($ x : ident) ($ y : ident) => {};}
macro_rules! derive_args_2 {derive () => {};}
macro_rules! derive_args_3 {derive ($ x : ident) => {};}
macro_rules! derive_dup_matcher {derive () {$ x : ident $ x : ident} => {}}
macro_rules! derive_unsafe {unsafe derive () {} => {}}
