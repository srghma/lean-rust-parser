#![allow(uncommon_codepoints)]
#[path = "issue-48508-aux.rs"]
mod other_file;
fn main() {
  other_file::other();
}
