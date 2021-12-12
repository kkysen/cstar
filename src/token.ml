open Core

type comment =
  | Structural (* /- ... *)
  | Line (* // *) of string
  | Block (* /* */ *) of string
[@@deriving show, yojson]

type number_base =
  | Binary (* 0b *)
  | Octal (* 0o *)
  | HexaDecimal (* 0x *)
  | Decimal
[@@deriving show, yojson]

let base_num ~(base : number_base) : int =
  match base with
  | Binary -> 2
  | Octal -> 8
  | HexaDecimal -> 16
  | Decimal -> 10
;;

let base_ranges ~(base : number_base) : (char * char) list =
  match base with
  | Binary -> [('0', '1')]
  | Octal -> [('0', '7')]
  | HexaDecimal -> [('0', '9'); ('A', 'F')]
  | Decimal -> [('0', '9')]
;;

let is_digit ~(base : number_base) (c : char) : (unit, string) result =
  let ranges = base_ranges ~base in
  let is_valid =
    ranges |> List.exists ~f:(fun (low, high) -> Char.between c ~low ~high)
  in
  if is_valid
  then Ok ()
  else (
    let regex =
      ranges
      |> List.map ~f:(fun (low, high) -> String.of_char_list [low; '-'; high])
      |> String.concat ?sep:(Some "")
    in
    let msg =
      Printf.sprintf
        "'%c' is not a valid digit of base %d (%s); must be in /%s/"
        c
        (base_num ~base)
        (show_number_base base)
        regex
    in
    Error msg)
;;

type sign =
  | Unspecified
  | Positive
  | Negative
[@@deriving show, yojson]

type raw_int_literal = {
    sign : sign
  ; base : number_base
  ; digits : string
}
[@@deriving show, yojson]

let parse_raw_int_literal (s : string) : raw_int_literal =
  let s = s |> String.to_list in
  let (sign, s) =
    match s with
    | '+' :: s -> (Positive, s)
    | '-' :: s -> (Negative, s)
    | s -> (Unspecified, s)
  in
  let (base, s) =
    match s with
    | '0' :: 'b' :: s -> (Binary, s)
    | '0' :: 'o' :: s -> (Octal, s)
    | '0' :: 'x' :: s -> (HexaDecimal, s)
    | s -> (Decimal, s)
  in
  let digits =
    s
    |> List.filter ~f:(fun c -> not (Char.equal c '_'))
    |> List.map ~f:(fun c ->
           match is_digit ~base c with
           | Ok () -> c
           | Error msg -> failwith msg)
    |> String.of_char_list
  in
  {sign; base; digits}
;;

type number_literal = {
    integral : raw_int_literal
  ; floating : raw_int_literal option (* is a float if it has a floating part *)
  ; exponent : raw_int_literal option
  ; suffix : string (* i32, f64, u1, x1000, usize, "" *)
}
[@@deriving show, yojson]

type char_literal = {
    prefix : string
  ; unescaped : string
}
[@@deriving show, yojson]

type string_literal = {
    prefix : string
  ; unescaped : string
}
[@@deriving show, yojson]

(* TODO format_string_literal *)

type literal =
  | Number of number_literal
  | Char of char_literal
  | String of string_literal
[@@deriving show, yojson]

type keyword = 
  | KwUse
  | KwLet
  | KwMut
  | KwPub
  | KwIn
  | KwTry
  | KwConst
  | KwImpl
  | KwFn
  | KwStruct
  | KwEnum
  | KwUnion
  | KwReturn
  | KwBreak
  | KwContinue
  | KwFor
  | KwWhile
  | KwIf
  | KwElse
  | KwMatch
  | KwDefer
  | KwUndefer
  | KwTrait
[@@deriving show, yojson]

let keyword_of_string (s : string) : keyword option = 
  match s with
  | "use" -> Some KwUse
  | "let" -> Some KwLet
  | "mut" -> Some KwMut
  | "pub" -> Some KwPub
  | "in" -> Some KwIn
  | "try" -> Some KwTry
  | "const" -> Some KwConst
  | "impl" -> Some KwImpl
  | "fn" -> Some KwFn
  | "struct" -> Some KwStruct
  | "enum" -> Some KwEnum
  | "union" -> Some KwUnion
  | "return" -> Some KwReturn
  | "break" -> Some KwBreak
  | "continue" -> Some KwContinue
  | "for" -> Some KwFor
  | "while" -> Some KwWhile
  | "if" -> Some KwIf
  | "else" -> Some KwElse
  | "match" -> Some KwMatch
  | "defer" -> Some KwDefer
  | "undefer" -> Some KwUndefer
  | "trait" -> Some KwTrait
  | _ -> None
;;

type token =
  | EOF
  | WhiteSpace of string (* ' \n\r\t', ... *)
  | Comment of comment
  | Literal of literal
  | Keyword of keyword
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
[@@deriving show, yojson]

type tokens = {
    path : string
  ; tokens : token list
}
[@@deriving show, yojson]
