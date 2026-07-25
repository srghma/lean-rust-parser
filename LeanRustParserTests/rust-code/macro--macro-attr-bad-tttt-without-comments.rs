#![crate_type = "lib"]
#![feature(macro_attr)]
macro_rules! attr_incomplete_1 { attr }
macro_rules! attr_incomplete_2 { attr() }
macro_rules! attr_incomplete_3 { attr() {} }
macro_rules! attr_incomplete_4 { attr() {} => }
macro_rules! attr_incomplete_5 { unsafe }
macro_rules! attr_incomplete_6 { unsafe attr }
macro_rules! attr_noparens_1 { attr{} {} => {} }
macro_rules! attr_noparens_2 { attr[] {} => {} }
macro_rules! attr_noparens_3 { attr _ {} => {} }
macro_rules! attr_dup_matcher_1 { attr() {$x:ident $x:ident} => {} }
macro_rules! attr_dup_matcher_2 { attr($x:ident $x:ident) {} => {} }
macro_rules! attr_dup_matcher_3 { attr($x:ident) {$x:ident} => {} }
