#![crate_type = "lib"]
#![expect(non_camel_case_types)]
#[rustfmt::skip]
mod garden {
    fn f<path>() where path:to::somewhere {}
    fn g(_: impl Take<path:to::somewhere>) {}
    #[cfg(false)] fn h() where a::path:to::nowhere {}
    fn i(_: impl Take<path::<>:to::somewhere>) {}
    mod to { pub(super) trait somewhere {} }
    trait Take { type path; }
}
