{
  open Core
  open Token
}

let sign = ['+' '-']? as sign
let int_base = ('0'(['b' 'o' 'x'] as base) '_'?)?
let digit = ['0'-'9' 'A'-'F' 'a'-'f']
let raw_int = int_base digit (digit|'_')*
let integral = raw_int
let float = raw_int "." raw_int

let ascii = ([' '-'!' '#'-'[' ']'-'~'])
let char = ''' (ascii) '''

(* let suffix = 'a-z' *)

(* https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AXID_Start%3A%5D&abb=on&g=&i=
   But only ascii for now
*)
let xid_start = ['a'-'z' 'A'-'Z']
(* https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AXID_Continue%3A%5D&abb=on&g=&i=
   But only ascii for now
*)
let xid_continue = xid_start | ['0'-'9' '_']

rule token = parse
  | eof { EOF }
  (* simple literal tokens *)
  | ';' { SemiColon }
  | ':' { Colon }
  | ',' { Comma }
  | '.' { Dot }
  | '(' { OpenParen }
  | ')' { CloseParen }
  | '{' { OpenBrace }
  | '}' { CloseBrace }
  | '[' { OpenBracket }
  | ']' { CloseBracket }
  | '@' { At }
  | '?' { QuestionMark }
  | '!' { ExclamationPoint }
  | '=' { Equal }
  | '<' { LessThan }
  | '>' { GreaterThan }
  | '+' { Plus }
  | '-' { Minus }
  | '*' { Times }
  | '/' { Divide }
  | '&' { And }
  | '|' { Or }
  | '^' { Caret }
  | '%' { Percent }
  | '~' { Tilde }
  | '#' { Pound }
  | '$' { DollarSign }
  (* whitespace *)
  | [' ' '\n' '\r' '\t' '\x0B' '\x0C']+ { WhiteSpace }
  (* comments *)
  (* Only match the actual structural "slashdash" comment, 
   * since we need to fully parse to know what it comments out. 
   *)
  | "/-" { Comment Structural }
  (* Could also be a doc comment if /// so definitely store the comment string. *)
  | "//" ([^ '\n' '\r']* as s) { Comment (Line s) }
  (* Need to do this recursively since block comments can be nested. *)
  | "/*" { Comment (Block (block_comment 0 "" lexbuf)) }
  (* string/char literals *)
  | (['b']? as prefix) '\'' { Literal (Char {prefix; unescaped = unescape_char_literal "" lexbuf}) }
  | (['b' 'c' 'r' 'f']? as prefix) '"' { Literal (String {prefix; unescaped = unescape_string_literal "" lexbuf}) }
  (* number literals *)
  (* If it ends in a '.', it could be a 
   *   float: 1.1
   *   member (field or method): 1.@sizeof()
   *   range: 1..2
   * If the character following the '.' is another digit,
   * then it has to be a float.
   * Note that hex floats, which can include 'a-fA-F',
   * naively don't follow this rule, which is why we require another `0x` prefix.
   * This also has the added benefit of allowing you to switch bases between the integral and floating parts.
   *)
  (* identifiers *)
  | ((['_' '$'] | xid_start) xid_continue*) as s { Identifier s }
  | _ as c { failwith (Printf.sprintf "illegal character: %c" c) }


(* https://stackoverflow.com/questions/7117975/how-to-deal-with-nested-comments-in-fslex
   How do I get the comment value, or do I even need to?
*)
and block_comment depth comment = parse
  | "*/" as s { match depth with
    | 0 -> s
    | _ -> block_comment (depth - 1) (comment ^ s) lexbuf
  }
  | "/*" as s { block_comment (depth + 1) (comment ^ s) lexbuf }
  | _  as c { block_comment depth (comment ^ String.of_char c) lexbuf }

and decode_char_escape = parse
  | ['\\' '\'' '"'] as c { c }
  | 'n' { '\n' }
  | 'r' { '\r' }
  | 't' { '\t' }
  | 'b' { '\b' }
  | 'v' { '\x0B' }
  | 'f' { '\x0C' }
  | _ as c { failwith (Printf.sprintf "illegal escape: %c" c) }

and unescape_char_literal s = parse
  | '\'' { s }
  | '\\' { unescape_char_literal (s ^ String.of_char (decode_char_escape lexbuf)) lexbuf }
  | _ as c { unescape_char_literal (s ^ String.of_char c) lexbuf }

(* modified from: https://github.com/realworldocaml/examples/blob/v1/code/parsing/lexer.mll *)
and unescape_string_literal s = parse
  | '"' { s }
  | '\\' { unescape_string_literal (s ^ String.of_char (decode_char_escape lexbuf)) lexbuf }
  | _ as c { unescape_string_literal (s ^ String.of_char c) lexbuf }
