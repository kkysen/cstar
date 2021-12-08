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

let test () : unit =
  (* let lexbuf = Lexing.from_string "fn main() {}" in *)
  (* let tokens = read_tokens lexbuf in *)
  (* tokens |> List.map Token.show_token |> List.iter print_endline in *)
  let tokens =
    {
      Token.path = "?"
    ; Token.tokens =
        [
          Token.EOF
        ; Token.WhiteSpace " " (* ' \n\r\t', ... *)
        ; Token.Comment Token.Structural
        ; Token.Comment (Token.Line "line comment")
        ; Token.Comment (Token.Block "block comment")
          (* ; Token.Literal (Token.Number) *)
        ; Token.Literal (Token.Char {unescaped = ","; prefix = ""})
        ; Token.Literal
            (Token.String {unescaped = "hello\\nworld"; prefix = "b"})
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
        ]
    }
  in
  let tokens_json = tokens |> Token.yojson_of_tokens |> Yojson.Safe.to_string in
  let example_type : Ast.type_ =
    Ast.Struct
      {
        Ast.struct_name = "Example"
      ; Ast.struct_fields =
          {
            map =
              StringMap.S.singleton
                "field"
                {
                  Ast.field_name = "field"
                ; Ast.field_type =
                    Ast.Primitive
                      (Ast.Int {Ast.unsigned = true; Ast.bits = Ast.Exact 64})
                ; Ast.publicity = Ast.Public
                }
          }
      }
  in
  let print_method : Ast.func_decl =
    {
      Ast.binding =
        {
          Ast.name = "print"
        ; Ast.publicity = Ast.Public
        ; Ast.annotations = []
        ; Ast.doc_comment = {Ast.lines = []}
        }
    ; Ast.func =
        {
          func_type =
            {
              Ast.func_name = "print"
            ; Ast.generic_args = {map = StringMap.S.empty}
            ; Ast.args =
                {
                  map =
                    StringMap.S.singleton
                      "self"
                      {Ast.variable_name = "self"; Ast.variable_type = Ast.Self}
                }
            ; Ast.return_type = Ast.Primitive Ast.Unit
            }
        ; Ast.func_value = Ast.Literal Ast.Unit
        }
    }
  in
  let main_func : Ast.value_let =
    {
      Ast.binding =
        {
          Ast.name = "main"
        ; Ast.publicity = Ast.Private
        ; Ast.annotations = []
        ; Ast.doc_comment = {Ast.lines = []}
        }
    ; Ast.value =
        Ast.Literal
          (Ast.Func
             {
               Ast.func_type =
                 {
                   Ast.func_name = "main"
                 ; Ast.generic_args = {map = StringMap.S.empty}
                 ; Ast.args = {map = StringMap.S.empty}
                 ; Ast.return_type = Ast.Primitive Ast.Unit
                 }
             ; Ast.func_value = Ast.Literal Ast.Unit
             })
    }
  in
  let ast =
    {
      Ast.path = "?"
    ; Ast.module_ =
        {
          Ast.name = "hello"
        ; Ast.items =
            [
              Ast.Let
                (Ast.Type
                   {
                     Ast.binding =
                       {
                         Ast.name = "Example"
                       ; Ast.publicity = Ast.Private
                       ; Ast.annotations = []
                       ; Ast.doc_comment = {Ast.lines = []}
                       }
                   ; Ast.value = example_type
                   })
            ; Ast.Impl
                {
                  Ast.impl_type = example_type
                ; Ast.impl_funcs =
                    {map = StringMap.S.singleton "print" print_method}
                }
            ; Ast.Let (Ast.Value main_func)
            ]
        }
    }
  in
  let ast_json = ast |> Ast.yojson_of_ast |> Yojson.Safe.pretty_to_string in
  ignore tokens_json;
  ignore ast_json;
  ()
;;

let main () : unit =
  test ();
  Driver.run ();
  ()
;;

let () = main ()
