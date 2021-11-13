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

let range ~(min : int) ~(max : int) : int list =
  let n = max - min in
  if n < 0 then [] else List.init n ~f:(fun i -> i + min)
;;

let range_inclusive ~(min : int) ~(max : int) : int list =
  range ~min ~max:(max + 1)
;;

type emit_type =
  | Src
  (* | Ast *)
  | Ir
  | Bc
  | Asm
  | Obj
  | Exe
[@@deriving show, eq, ord, enum]

let emit_type_of_enum_exn (i : int) : emit_type =
  i |> emit_type_of_enum |> Option.value_exn
;;

let emit_type_all : emit_type list = [Src; (* Ast; *) Ir; Bc; Asm; Obj; Exe]

let emit_type_to_string (this : emit_type) =
  match this with
  | Src -> "src"
  (* | Ast -> "ast" *)
  | Ir -> "ir"
  | Bc -> "bc"
  | Asm -> "asm"
  | Obj -> "obj"
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
  (* | Ast -> ".ast.json" *)
  | Ir -> ".ll"
  | Bc -> ".bc"
  | Asm -> ".s"
  | Obj -> ".o"
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

let emit_type_is_llvm (this : emit_type) : bool =
  match this with
  | Src -> false
  (* | Ast -> false *)
  | Ir -> true
  | Bc -> true
  | Asm -> true
  | Obj -> true
  | Exe -> true
;;

let quote_arg (arg : string) : string =
  if String.contains arg ' ' then "\"" ^ arg ^ "\"" else arg
;;

let argv_to_string (argv : string list) : string =
  argv |> List.map ~f:quote_arg |> String.concat ?sep:(Some " ")
;;

let compile_file
    ~(src_path : string)
    ~(src_type : emit_type option)
    ~(out_path : string option)
    ~(out_type : emit_type option)
    ~(temps_dir : string option)
    ~(print_driver_commands : bool)
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
           let (dir_and_stem, _) = Filename.split_extension src_path in
           let ext = emit_type_extension out_type in
           dir_and_stem ^ ext)
  in

  if String.equal src_path out_path
  then failwith "src and out path are the same";

  (* match compare_emit_type src_type out_type with | -1 -> () | 0 -> ( (* file
     can't be the same; just do a simple copy then *)

     ) | 1 -> failwith "can't decompile"; *)

  (* TODO at least match llvm's -save-temps=obj, too*)
  let temps_dir =
    temps_dir
    |> value_or_thunk ~default:(fun () ->
           Filename.temp_dir (Filename.basename src_path) ".cstar")
  in
  let out_name =
    let base = Filename.basename out_path in
    let (stem, _) = Filename.split_extension base in
    stem
  in
  let temp_path emit_type =
    Filename.concat temps_dir (out_name ^ emit_type_extension emit_type)
  in

  let subcommands =
    range ~min:(emit_type_to_enum src_type) ~max:(emit_type_to_enum out_type)
    |> List.map ~f:(fun i ->
           (emit_type_of_enum_exn i, emit_type_of_enum_exn (i + 1)))
    |> List.map ~f:(fun (src, out) ->
           [
             "cstar"
           ; "compile-raw"
           ; "--src"
           ; (if equal_emit_type src src_type then src_path else temp_path src)
           ; "--src-type"
           ; emit_type_to_string src
           ; "--output"
           ; (if equal_emit_type out out_type then out_path else temp_path out)
           ; "--out-type"
           ; emit_type_to_string out
           ])
  in

  if List.is_empty subcommands
  then failwith "nothing to compile and cannot decompile";

  let print_subcommand argv = argv |> argv_to_string |> print_endline in

  let run_subcommand argv =
    let pid =
      Unix.fork_exec ~prog:Sys.executable_name ~argv ?use_path:(Some false) ()
    in
    let (_, status) = Unix.wait ?restart:(Some true) (`Pid pid) in
    let _status = Result.ok status in
    ()
  in

  let subcommand_fun =
    if print_driver_commands then print_subcommand else run_subcommand
  in

  subcommands |> List.iter ~f:subcommand_fun;

  (* TODO: clean up temp dir *)
  ()
;;

let compile_file_raw
    ~(src_path : string)
    ~(src_type : emit_type)
    ~(out_path : string)
    ~(out_type : emit_type)
    : unit
  =
  let llvm_command =
    match (src_type, out_type) with
    | (Src, Ir) -> None
    (* | (Src, Ast) | (Ast, Ir) -> failwith "C* ast not currently supported" *)
    (* prefer delegating to clang since it knows how to invoke llvm better *)
    | (Ir, Bc) -> Some ["clang"; "-x"; "ir"; "-emit-llvm"; "-c"]
    | (Bc, Asm) -> Some ["llc"; "--filetype=asm"]
    | (Asm, Obj) -> Some ["clang"; "-c"]
    | (Obj, Exe) -> Some ["clang"; "-fuse-ld=lld"]
    | _ -> failwith "invalid src and out types for compile-raw"
  in
  match llvm_command with
  | Some args ->
      let argv = args @ ["-o"; out_path; src_path] in
      let prog = args |> List.find ~f:(fun _ -> true) |> Option.value_exn in
      let (_ : never_returns) =
        Unix.exec ~prog ~argv ?use_path:(Some true) ()
      in
      ()
  | None ->
      ();

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
  let env_var = "COMMAND_OUTPUT_INSTALLATION_" ^ String.uppercase shell in
  let env = `Extend [(env_var, "1")] in
  let (_ : never_returns) =
    Unix.exec
      ~prog:Sys.executable_name
      ~argv:["cstar"]
      ?use_path:(Some false)
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
        and temps_dir =
          flag
            "--save-temps"
            (optional Filename.arg_type)
            ~doc:"save-temps save all temporaries"
        and print_driver_commands =
          flag
            "--print-driver-commands"
            no_arg
            ~doc:"print-driver-commands print a dry run of the driver commands"
        in
        fun () ->
          compile_file
            ~src_path
            ~src_type
            ~out_path
            ~out_type
            ~temps_dir
            ~print_driver_commands)
  in
  let compile_raw =
    Command.basic
      ~summary:"compile a C* source file"
      Command.Let_syntax.(
        let%map_open src_path =
          flag "--src" (required Filename.arg_type) ~doc:"src src file"
        and src_type =
          flag
            "--src-type"
            (required emit_arg)
            ~doc:"src-type type of source if not inferred"
        and out_path =
          flag "--output" (required Filename.arg_type) ~doc:"output output file"
        and out_type =
          flag
            "--out-type"
            (required emit_arg)
            ~doc:"out-type what to output/emit"
        in
        fun () -> compile_file_raw ~src_path ~src_type ~out_path ~out_type)
  in
  Command.group
    ~summary:"the C* compiler"
    ~readme:(fun () -> "See README.md")
    [
      ("completions", completions)
    ; ("compile", compile)
    ; ("compile-raw", compile_raw)
    ]
;;

let () = make_cmd () |> Command.run ~version:"0.1" ~build_info:""
