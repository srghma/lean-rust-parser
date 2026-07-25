fn main() {}
macro_rules! expand_to_enum {() => {enum BadE {}};}
macro_rules! mac_impl {($ ($ i : item) *) => {struct S ; impl S {$ ($ i) *}}}
mac_impl!{struct BadS ; expand_to_enum ! () ;}
macro_rules! mac_trait {($ ($ i : item) *) => {trait T {$ ($ i) *}}}
mac_trait!{struct BadS ; expand_to_enum ! () ;}
macro_rules! mac_extern {($ ($ i : item) *) => {extern "C" {$ ($ i) *}}}
mac_extern!{struct BadS ; expand_to_enum ! () ;}
