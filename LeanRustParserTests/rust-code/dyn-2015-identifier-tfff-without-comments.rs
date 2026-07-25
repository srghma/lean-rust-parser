#![cfg(fail)]
type A0 = dyn;
type A1 = dyn::dyn;
type A2 = dyn<dyn, dyn>;
type A3 = dyn<<dyn as dyn>::dyn>;
type A4 = dyn + dyn;
