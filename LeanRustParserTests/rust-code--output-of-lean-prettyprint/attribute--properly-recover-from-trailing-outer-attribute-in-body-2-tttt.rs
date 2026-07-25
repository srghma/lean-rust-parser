macro_rules! the_macro {($ foo : stmt ; $ bar : stmt ;) => {# [cfg ()] $ foo # [cfg (false)] $ bar}}
fn main() {
  the_macro!(() ; () ;);
}
