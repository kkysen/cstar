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
      Ast.module_ =
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
  ast |> Ast.show_ast |> print_endline;
  ()
;;

open Core

type emit_type =
  | Exe
  | Asm
  | Bc
  | Ir
  | Ast

let emit_type_all : emit_type list = [Exe; Asm; Bc; Ir; Ast]

let emit_type_to_string (this : emit_type) =
  match this with
  | Exe -> "exe"
  | Asm -> "asm"
  | Bc -> "bc"
  | Ir -> "ir"
  | Ast -> "ast"
;;

let emit_type_of_string (s : string) : emit_type =
  emit_type_all
  |> List.find ~f:(fun it : bool -> String.equal s (emit_type_to_string it))
  |> Option.value_exn ?message:(Some "invalid emit type")
;;

let emit_type_extension (emit : emit_type) : string =
  match emit with
  | Exe -> ""
  | Asm -> ".s"
  | Bc -> ".bc"
  | Ir -> ".ll"
  | Ast -> ".ast.json"
;;

let emit_arg =
  emit_type_all
  |> List.map ~f:(fun it -> (emit_type_to_string it, it))
  |> String.Map.of_alist_exn
  |> Command.Arg_type.of_map
;;

(* https://github.com/janestreet/base/blob/master/src/option.ml#L108 Like
   https://doc.rust-lang.org/std/option/enum.Option.html#method.unwrap_or_else *)
let value_or_thunk o ~default =
  match o with
  | Some x -> x
  | None -> default ()
;;

let compile_file
    ~(src_path : string)
    ~(out_path : string option)
    ~(emitting : emit_type)
    : unit
  =
  let out_path =
    out_path
    |> value_or_thunk ~default:(fun () ->
           let base = Filename.chop_extension src_path in
           let ext = emit_type_extension emitting in
           base ^ ext)
  in
  Printf.printf "%s => %s" src_path out_path;
;;

let generate_completions (shell : string option) : unit =
  let shell =
    shell
    |> Option.bind ~f:(fun _ ->
           Sys.getenv "SHELL" |> Option.map ~f:Filename.basename)
    |> Option.value ~default:"bash"
  in
  Printf.printf "shell = %s" shell;
  let own_exe = Sys.executable_name in
  let env_var = "COMMAND_OUTPUT_INSTALLATION_" ^ String.uppercase shell in
  let env = `Extend [(env_var, "1")] in
  let (_ : never_returns) =
    Unix.exec
      ~prog:own_exe
      ~argv:["cstar"]
      ?use_path:(Some true)
      ?env:(Some env)
      ()
  in
  ()
;;

let make_cmd () : Core.Command.t =
  let completions =
    Command.basic
      ~summary:"generate autocompletions"
      Command.Let_syntax.(
        let%map_open shell = anon (maybe ("shell" %: string)) in
        fun () -> generate_completions shell)
  in
  let compile =
    Command.basic
      ~summary:"compile a C* source file"
      Command.Let_syntax.(
        let%map_open src_path = anon ("source_file" %: Filename.arg_type)
        and out_path =
          flag
            ?aliases:(Some ["-o"])
            "--output"
            (optional Filename.arg_type)
            ~doc:"output output file"
        and emitting =
          flag
            "--emit"
            (optional_with_default Exe emit_arg)
            ~doc:"emit emit what"
        in
        fun () -> compile_file ~src_path ~out_path ~emitting)
  in
  Command.group
    ~summary:"the C* compiler"
    ~readme:(fun () -> "See README.md")
    [("completions", completions); ("compile", compile)]
;;

let () = make_cmd () |> Command.run ~version:"0.1" ~build_info:""
