type comment =
  | Structural (* /- ... *)
  | Line (* // *) of string
  | Block (* /* */ *) of string

type number_base =
  | Binary (* 0b *)
  | Octal (* 0o *)
  | HexaDecimal (* 0x *)
  | Decimal

type sign =
  | None
  | Positive
  | Negative

type raw_int_literal = {
    sign : sign
  ; base : number_base
  ; number : string
}

type number_literal = {
    integral : raw_int_literal
  ; floating : raw_int_literal option (* is a float if it has a floating part *)
  ; exponent : raw_int_literal option
  ; suffix : string (* i32, f64, u1, x1000, usize, "" *)
}

type char_literal = {
    unescaped : string
  ; prefix : string
}

type string_literal = {
    unescaped : string
  ; prefix : string
}

(* TODO format_string_literal *)

type literal =
  | Number of number_literal
  | Char of char_literal
  | String of string_literal

type token =
  | WhiteSpace (* ' \n\r\t', ... *)
  | Comment of comment
  | Literal of literal
  | Identifier of string
  | SemiColon (* ; *)
  | Colon (* : *)
  | Comma (* , *)
  | Dot (* . *)
  | OpenParen (* ( *)
  | CloseParen (* ) *)
  | OpenBrace (* { *)
  | CloseBrace (* } *)
  | OpenBracket (* [ *)
  | CloseBracket (* ] *)
  | At (* @ *)
  | QuestionMark (* ? *)
  | ExclamationPoint (* ! *)
  | Equal (* = *)
  | LessThan (* < *)
  | GreaterThan (* > *)
  | Plus (* + *)
  | Minus (* - *)
  | Times (* * *)
  | Divide (* / *)
  | And (* & *)
  | Or (* | *)
  | Caret (* ^ *)
  | Percent (* % *)
  | Tilde (* ~ *)
  | Pound (* # *)
  | DollarSign (* $ *)
  | Unknown