module

public import LeanRustParser.Basic.MacroRuleToken

@[expose] public section

instance : ToString Ident := ⟨(·.name)⟩

def MacroRuleToken.spelling : MacroRuleToken → String
  | .ident text _ => text
  | .lifetime text _ => "'" ++ text
  | MacroRuleToken.literal lit => lit.symbol
  | .eq => "=" | .lt => "<" | .le => "<=" | .eqEq => "==" | .ne => "!=" | .ge => ">=" | .gt => ">"
  | .andAnd => "&&" | .orOr => "||" | .bang => "!" | .tilde => "~" | .plus => "+" | .minus => "-"
  | .star => "*" | .slash => "/" | .percent => "%" | .caret => "^" | .and => "&" | .or => "|"
  | .shl => "<<" | .shr => ">>" | .plusEq => "+=" | .minusEq => "-=" | .starEq => "*=" | .slashEq => "/="
  | .percentEq => "%=" | .caretEq => "^=" | .andEq => "&=" | .orEq => "|=" | .shlEq => "<<=" | .shrEq => ">>="
  | .at => "@" | .dot => "." | .dotDot => ".." | .dotDotDot => "..." | .dotDotEq => "..="
  | .comma => "," | .semi => ";" | .colon => ":" | .pathSep => "::" | .rArrow => "->" | .lArrow => "<-"
  | .fatArrow => "=>" | .pound => "#" | .dollar => "$" | .question => "?" | .singleQuote => "'"
  | .openParen => "(" | .closeParen => ")" | .openBrace => "{" | .closeBrace => "}" | .openBracket => "[" | .closeBracket => "]"
  | .docComment _ _ symbol => symbol
  | .eof => ""
--   | .ident text _ | .lifetime text _ => text
--   | .ntIdent id _ | .ntLifetime id _ => id.name
--   | Token.keyword keyword => keyword.spelling
--   | .literal lit => lit.symbol
--   | .eq => "=" | .lt => "<" | .le => "<=" | .eqEq => "==" | .ne => "!=" | .ge => ">=" | .gt => ">"
--   | .andAnd => "&&" | .orOr => "||" | .bang => "!" | .tilde => "~" | .plus => "+" | .minus => "-"
--   | .star => "*" | .slash => "/" | .percent => "%" | .caret => "^" | .and => "&" | .or => "|"
--   | .shl => "<<" | .shr => ">>" | .plusEq => "+=" | .minusEq => "-=" | .starEq => "*=" | .slashEq => "/="
--   | .percentEq => "%=" | .caretEq => "^=" | .andEq => "&=" | .orEq => "|=" | .shlEq => "<<=" | .shrEq => ">>="
--   | .at => "@" | .dot => "." | .dotDot => ".." | .dotDotDot => "..." | .dotDotEq => "..="
--   | .comma => "," | .semi => ";" | .colon => ":" | .pathSep => "::" | .rArrow => "->" | .lArrow => "<-"
--   | .fatArrow => "=>" | .pound => "#" | .dollar => "$" | .question => "?" | .singleQuote => "'"
--   | .openParen => "(" | .closeParen => ")" | .openBrace => "{" | .closeBrace => "}" | .openBracket => "[" | .closeBracket => "]"
--   | .openInvisible _ | .closeInvisible _ | .eof => ""

/-- `rustc_ast::token::Token::is_punct`, excluding delimiters. -/
def MacroRuleToken.isPunctuation : MacroRuleToken → Bool
  | .eq | .lt | .le | .eqEq | .ne | .ge | .gt | .andAnd | .orOr | .bang | .tilde
  | .plus | .minus | .star | .slash | .percent | .caret | .and | .or | .shl | .shr
  | .plusEq | .minusEq | .starEq | .slashEq | .percentEq | .caretEq | .andEq | .orEq
  | .shlEq | .shrEq | .at | .dot | .dotDot | .dotDotDot | .dotDotEq | .comma | .semi
  | .colon | .pathSep | .rArrow | .lArrow | .fatArrow | .pound | .dollar | .question
  | .singleQuote => true
  | _ => false
