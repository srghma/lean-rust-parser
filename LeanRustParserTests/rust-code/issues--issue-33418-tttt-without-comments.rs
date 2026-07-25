trait Tr: !SuperA {}
trait Tr2: SuperA + !SuperB {}
trait Tr3: !SuperA + SuperB {}
trait Tr4: !SuperA + SuperB + !SuperC + SuperD {}
trait Tr5: !SuperA + !SuperB {}
trait SuperA {}
trait SuperB {}
trait SuperC {}
trait SuperD {}
fn main() {}
