let list_from_fn (f : unit -> 'a option) : 'a list =
  let rec next list =
    match f () with
    | None -> list
    | Some e -> next (e :: list)
  in
  next []
;;

let read_tokens (lexbuf : Lexing.lexbuf) : Token.token list =
  list_from_fn (fun () ->
      match Lexer.token lexbuf with
      | Token.EOF -> None
      | token -> Some token)
;;

let () =
  (* let lexbuf = Lexing.from_string "fn main() {}" in *)
  (* let tokens = read_tokens lexbuf in *)
  (* tokens |> List.map Token.show_token |> List.iter print_endline in *)
  let tokens =
    [
      Token.EOF
    ; Token.WhiteSpace (* ' \n\r\t', ... *)
    ; Token.Comment Token.Structural
    ; Token.Comment (Token.Line "line comment")
    ; Token.Comment (Token.Block "block comment")
    (* ; Token.Literal (Token.Number) *)
    ; Token.Literal (Token.Char {unescaped = ","; prefix = ""})
    ; Token.Literal (Token.String {unescaped = "hello\\nworld"; prefix = "b"})
    ; Token.Identifier "identifier"
    ; Token.SemiColon (* ; *)
    ; Token.Colon (* : *)
    ; Token.Comma (* , *)
    ; Token.Dot (* . *)
    ; Token.OpenParen (* ( *)
    ; Token.CloseParen (* ) *)
    ; Token.OpenBrace (* { *)
    ; Token.CloseBrace (* } *)
    ; Token.OpenBracket (* [ *)
    ; Token.CloseBracket (* ] *)
    ; Token.At (* @ *)
    ; Token.QuestionMark (* ? *)
    ; Token.ExclamationPoint (* ! *)
    ; Token.Equal (* = *)
    ; Token.LessThan (* < *)
    ; Token.GreaterThan (* > *)
    ; Token.Plus (* + *)
    ; Token.Minus (* - *)
    ; Token.Times (* * *)
    ; Token.Divide (* / *)
    ; Token.And (* & *)
    ; Token.Or (* | *)
    ; Token.Caret (* ^ *)
    ; Token.Percent (* % *)
    ; Token.Tilde (* ~ *)
    ; Token.Pound (* # *)
    ; Token.DollarSign (* $ *)
    ; Token.Unknown
    ]
  in
  tokens |> List.to_seq |> Seq.map Token.show_token |> Seq.iter print_endline;
  let ast = {Ast.module_ = {Ast.name = "hello"; Ast.items = []}} in
  ast |> Ast.show_ast |> print_endline;
  ()
;;
