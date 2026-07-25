#[cfg(target-os = "windows")]
pub fn test1() {}
#[cfg(target_os = %)]
pub fn test2() {}
#[cfg(target_os?)]
pub fn test3() {}
#[cfg[target_os]]
pub fn test4() {}
pub fn main() {}
