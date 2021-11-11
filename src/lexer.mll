{ 
open Token
exception InvalidChar of string 
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

rule token = parse
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
  | '"' { read_string (Buffer.create 80) lexbuf }
  | [' ' '\n' '\r' '\t' '\x0B' '\x0C']+ { WhiteSpace }
  (* Only match the actual structural "slashdash" comment, 
   * since we need to fully parse to know what it comments out. 
   *)
  | "/-" { Comment Structural }
  (* Could also be a doc comment if /// so definitely store the comment string. *)
  | "//" ([^ '\n' '\r']* as s) { Comment (Line s) }
  (* Need to do this recursively since block comments can be nested. *)
  | "/*" { block_comment 0 lexbuf }
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
  (*Number Data Types*)
  | "integral" { Literal Number }
  | "float" { Literal Number }



(* https://stackoverflow.com/questions/7117975/how-to-deal-with-nested-comments-in-fslex
   How do I get the comment value, or do I even need to?
*)
and block_comment depth = parse
  | "*/" { match depth with
             | 0 -> token lexbuf
             | _ -> block_comment (depth - 1) lexbuf
         }
  | "/*" { block_comment (depth + 1) lexbuf }
  | _ { block_comment depth lexbuf }
  
(*Modified: https://github.com/realworldocaml/examples/blob/v1/code/parsing/lexer.mll*)
and read_string buf = parse
  | '"' { STRING (Buffer.contents buf) }
    (*we have to escape '\' so '\\' needed*)
  | '\\' '/' { Buffer.add_char buf '/'; read_string buf lexbuf } 
  | '\\' '\\' { Buffer.add_char buf '\\'; read_string buf lexbuf } 
  | '\\' 'b' { Buffer.add_char buf '\b'; read_string buf lexbuf } 
  | '\\' 'f' { Buffer.add_char buf '\012'; read_string buf lexbuf } 
  | '\\' 'n' { Buffer.add_char buf '\n'; read_string buf lexbuf } 
  | '\\' 'r' { Buffer.add_char buf '\r'; read_string buf lexbuf } 
  | '\\' 't' { Buffer.add_char buf '\t'; read_string buf lexbuf } 
  | [^ '"' '\\']+ (*processing any char in the string that is not an escape*)
{ Buffer.add_string buf (Lexing.lexeme lexbuf); 
  read_string buf lexbuf
}
  (*catch all for any invalid char in our string*)
  | _ { (raise (InvalidChar("Illegal string character: " ^ Lexing.lexeme lexbuf))) }