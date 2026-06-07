module

@[expose] public section

/-! ──────────────────────────────────────────────────────────────
    § 1  Doc combinator
──────────────────────────────────────────────────────────────── -/

/-- A very small pretty-printer combinator. -/
structure Doc where
  render : Nat → String
  deriving Inhabited

namespace Doc

def text (s : String) : Doc  := ⟨fun _ => s⟩
def empty : Doc              := text ""
def nl    : Doc              := ⟨fun n => "\n" ++ String.ofList (List.replicate (n * 2) ' ')⟩
def indent (d : Doc) : Doc   := ⟨fun n => d.render (n + 1)⟩

def append (a b : Doc) : Doc := ⟨fun n => a.render n ++ b.render n⟩
instance : Append Doc        := ⟨append⟩

def join (sep : Doc) : List Doc → Doc
  | []      => empty
  | [x]     => x
  | x :: xs => x ++ sep ++ join sep xs

def commaList  (ds : List Doc) : Doc := join (text ", ") ds
def commaLine  (ds : List Doc) : Doc := join (text "," ++ nl) ds

/-- `open_ { indent(nl ++ body) nl close_ }` -/
def braced (open_ close_ : String) (body : Doc) : Doc :=
  text open_ ++ indent (nl ++ body) ++ nl ++ text close_

def bracedInline (open_ close_ : String) (body : Doc) : Doc :=
  text open_ ++ body ++ text close_

def toString (d : Doc) : String := d.render 0

end Doc
