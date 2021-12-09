{
  open Token
  
  let of_char = Core.String.of_char
}

(* https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AXID_Start%3A%5D&abb=on&g=&i=
   But only ascii for now
*)
let xid_start = ['a'-'z' 'A'-'Z']
(* https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%3AXID_Continue%3A%5D&abb=on&g=&i=
   But only ascii for now
*)
let xid_continue = xid_start | ['0'-'9' '_']

let identifier = (['_' '$'] | xid_start) xid_continue*

(* let binary_digit = ['0'-'1']
let octal_digit = ['0'-'7']
let decimal_digit = ['0'-'9']
let hex_digit = ['0'-'9' 'A'-'F' 'a'-'f']

let raw_binary_int = "0b" ((binary_digit | '_')* binary_digit as digits)
let raw_octal_int = "0o" ((octal_digit | '_')* octal_digit as digits)
let raw_hex_int = "0x" ((hex_digit | '_')* hex_digit as digits)
let raw_decimal_int = (decimal_digit | (decimal_digit (decimal_digit | '_')* decimal_digit)) as digits

let sign = ['+' '-']? as sign
let raw_int = raw_binary_int | raw_octal_int | raw_decimal_int | raw_hex_int
let num_suffix = identifier? as suffix

let integral = sign raw_int
let floating = '.' raw_int
let exponent = ['e' 'E'] sign raw_int

let num = integral floating? exponent? num_suffix *)

let sign = ['+' '-']?
let digit = ['0'-'9' 'A'-'F']
let raw_int = ('0' ['b' 'o' 'x'] '_'?)? (digit | (digit (digit | '_')* digit))
let integral = (sign raw_int as integral)
let floating = '.' (raw_int as floating)
let exponent = 'e' (sign raw_int as exponent)
let num = integral floating? exponent? (identifier as suffix)?

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
  | ([' ' '\n' '\r' '\t' '\x0B' '\x0C']+) as s { WhiteSpace s }
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
  (* identifiers *)
  | (identifier) as s { Identifier s }
  (* number literals *)
  | num { Literal (Number ({
      integral = integral |> parse_raw_int_literal
    ; floating = floating |> Option.map parse_raw_int_literal
    ; exponent = exponent |> Option.map parse_raw_int_literal
    ; suffix = suffix |> Option.value ~default:""
  })) }
  | _ as c { failwith (Printf.sprintf "illegal character: %c" c) }


(* https://stackoverflow.com/questions/7117975/how-to-deal-with-nested-comments-in-fslex
   How do I get the comment value, or do I even need to?
*)
and block_comment depth comment = parse
  | "*/" as s { match depth with
    | 0 -> comment
    | _ -> block_comment (depth - 1) (comment ^ s) lexbuf
  }
  | "/*" as s { block_comment (depth + 1) (comment ^ s) lexbuf }
  | _  as c { block_comment depth (comment ^ of_char c) lexbuf }

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
  | '\\' { unescape_char_literal (s ^ of_char (decode_char_escape lexbuf)) lexbuf }
  | _ as c { unescape_char_literal (s ^ of_char c) lexbuf }

(* modified from: https://github.com/realworldocaml/examples/blob/v1/code/parsing/lexer.mll *)
and unescape_string_literal s = parse
  | '"' { s }
  | '\\' { unescape_string_literal (s ^ of_char (decode_char_escape lexbuf)) lexbuf }
  | _ as c { unescape_string_literal (s ^ of_char c) lexbuf }
