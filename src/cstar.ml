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

(* https://github.com/janestreet/base/blob/master/src/option.ml#L108 Like
   https://doc.rust-lang.org/std/option/enum.Option.html#method.unwrap_or_else *)
let value_or_thunk o ~default =
  match o with
  | Some x -> x
  | None -> default ()
;;

type emit_type =
  | Src
  | Ast
  | Ir
  | Bc
  | Asm
  | Exe

let emit_type_all : emit_type list = [Src; Ast; Ir; Bc; Asm; Exe]

let emit_type_to_string (this : emit_type) =
  match this with
  | Src -> "src"
  | Ast -> "ast"
  | Ir -> "ir"
  | Bc -> "bc"
  | Asm -> "asm"
  | Exe -> "exe"
;;

let emit_type_of_string (s : string) : emit_type =
  emit_type_all
  |> List.find ~f:(fun it -> String.equal s (emit_type_to_string it))
  |> Option.value_exn ?message:(Some "invalid emit type")
;;

let emit_type_extension (this : emit_type) : string =
  match this with
  | Src -> ".cstar"
  | Ast -> ".ast.json"
  | Ir -> ".ll"
  | Bc -> ".bc"
  | Asm -> ".s"
  | Exe -> ""
;;

let emit_type_detect_by_extension (path : string) : emit_type option =
  let ext =
    path
    |> Filename.split_extension
    |> snd
    |> Option.map ~f:(fun ext -> "." ^ ext)
    |> Option.value ~default:""
  in
  emit_type_all
  |> List.find ~f:(fun it -> String.equal ext (emit_type_extension it))
;;

(* TODO For example, llvm bitcode starts with `BC\OxCO\OxD\OxE` (`BCOxC0DE`). *)
let emit_type_detect_by_magic (_path : string) : emit_type option = None

let emit_type_detect (path : string) : emit_type option =
  [emit_type_detect_by_extension; emit_type_detect_by_magic]
  |> List.fold ~init:(Ok ()) ~f:(fun acc f ->
         match acc with
         | Ok () -> (
             match f path with
             | Some emit -> Error emit
             | None -> Ok ())
         | Error emit -> Error emit)
  |> Result.error
;;

let emit_type_detect_exn (path : string) : emit_type =
  path
  |> emit_type_detect
  |> Option.value_exn ?message:(Some "couldn't detect file type")
;;

let emit_arg =
  emit_type_all
  |> List.map ~f:(fun it -> (emit_type_to_string it, it))
  |> String.Map.of_alist_exn
  |> Command.Arg_type.of_map
;;

let compile_file
    ~(src_path : string)
    ~(src_type : emit_type option)
    ~(out_path : string option)
    ~(out_type : emit_type option)
    ~(save_temps : bool)
    : unit
  =
  let src_type =
    src_type
    |> value_or_thunk ~default:(fun () -> emit_type_detect_exn src_path)
  in
  let out_type =
    out_type
    |> value_or_thunk ~default:(fun () ->
           match out_path with
           | Some out_path -> emit_type_detect_exn out_path
           | None -> Exe)
  in
  let out_path =
    out_path
    |> value_or_thunk ~default:(fun () ->
           let base = Filename.chop_extension src_path in
           let ext = emit_type_extension out_type in
           base ^ ext)
  in
  let temps_dir =
    match save_temps with
    | true -> Filename.dirname out_path
    | false -> Filename.temp_dir (Filename.basename src_path) ".cstar"
  in
  ignore src_type;
  ignore temps_dir;
  Printf.printf "%s => %s" src_path out_path;
  (* TODO: clean up temp dir *)
  ()
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
        and src_type =
          flag
            "--src-type"
            (optional emit_arg)
            ~doc:"src-type type of source if not inferred"
        and out_path =
          flag
            ?aliases:(Some ["-o"])
            "--output"
            (optional Filename.arg_type)
            ~doc:"output output file"
        and out_type =
          flag
            ?aliases:(Some ["--emit"])
            "--out-type"
            (optional emit_arg)
            ~doc:"out-type what to output/emit"
        and save_temps =
          flag "--save-temps" no_arg ~doc:"save-temps save all temporaries"
        in
        fun () ->
          compile_file ~src_path ~src_type ~out_path ~out_type ~save_temps)
  in
  Command.group
    ~summary:"the C* compiler"
    ~readme:(fun () -> "See README.md")
    [("completions", completions); ("compile", compile)]
;;

let () = make_cmd () |> Command.run ~version:"0.1" ~build_info:""
