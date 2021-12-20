open Core

let range ~(min : int) ~(max : int) : int list =
  let n = max - min in
  if n < 0 then [] else List.init n ~f:(fun i -> i + min)
;;

let _range_inclusive ~(min : int) ~(max : int) : int list =
  range ~min ~max:(max + 1)
;;

let quote_arg (arg : string) : string =
  if String.contains arg ' ' then "\"" ^ arg ^ "\"" else arg
;;

let argv_to_string (argv : string list) : string =
  argv |> List.map ~f:quote_arg |> String.concat ?sep:(Some " ")
;;

type raw_compile_args = {
    src_path : string
  ; src_type : EmitType.t
  ; out_path : string
  ; out_type : EmitType.t
}
[@@deriving show]

let run_subprocess ~(program : string) ~(argv : string list) ~(use_path : bool)
    : unit
  =
  let pid = Unix.fork_exec ~prog:program ~argv ?use_path:(Some use_path) () in
  let (_, status) = Unix.wait ?restart:(Some true) (`Pid pid) in
  status
  |> Result.map_error ~f:(fun e ->
         let cmd = argv |> argv_to_string in
         let exit_message = Error e |> Unix.Exit_or_signal.to_string_hum in
         let message = cmd ^ ": " ^ exit_message in
         failwith message)
  |> Result.ok_exn
;;

let compile_file_raw ~(args : raw_compile_args) : unit =
  let {src_path; src_type; out_path; out_type} = args in
  if EmitType.is_llvm src_type && EmitType.is_llvm out_type
  then (
    let args =
      match (src_type, out_type) with
      (* | (Src, Ast) | (Ast, Ir) -> failwith "C* ast not currently supported" *)
      (* prefer delegating to clang since it knows how to invoke llvm better *)
      | (Ir, Bc) -> ["clang"; "-x"; "ir"; "-emit-llvm"; "-c"]
      | (Bc, Asm) -> ["llc"; "--filetype=asm"]
      | (Asm, Obj) -> ["clang"; "-c"]
      | (Obj, Exe) -> ["clang"; "-fuse-ld=lld"]
      | _ -> failwith "invalid src and out llvm types for compile-raw"
    in
    let argv = args @ ["-o"; out_path; src_path] in
    let program = args |> List.find ~f:(fun _ -> true) |> Option.value_exn in
    run_subprocess ~program ~argv ~use_path:true;
    ())
  else (
    let compile_file =
      match (src_type, out_type) with
      | (Src, Tokens) -> Compiler.Lex.compile_file
      | (Tokens, Ast) -> Compiler.Parse.compile_file
      | (Ast, DesugaredAst) -> Compiler.Desugar.compile_file
      | (DesugaredAst, TypedAst) -> Compiler.TypeCheck.compile_file
      | (TypedAst, Ir) -> Compiler.CodeGen.compile_file
      | _ -> failwith "invalid src and out cstar types for compile-raw"
    in
    compile_file ~input_path:src_path ~output_path:out_path;
    ())
;;

let run_raw_compile
    ~(args : raw_compile_args)
    ~(print : bool)
    ~(in_new_process : bool)
    : unit
  =
  let print_command argv = argv |> argv_to_string |> print_endline in

  if print || in_new_process
  then (
    let {src_path; src_type; out_path; out_type} = args in
    let argv =
      [
        "cstar"
      ; "compile-raw"
      ; "--src"
      ; src_path
      ; "--src-type"
      ; EmitType.to_string src_type
      ; "--output"
      ; out_path
      ; "--out-type"
      ; EmitType.to_string out_type
      ]
    in
    if print
    then print_command argv
    else run_subprocess ~program:Sys.executable_name ~argv ~use_path:false)
  else compile_file_raw ~args
;;

let compile_file
    ~(src_path : string)
    ~(src_type : EmitType.t option)
    ~(out_path : string option)
    ~(out_type : EmitType.t option)
    ~(temps_dir : string option)
    ~(print_driver_commands : bool)
    ~(no_exe_extension : bool)
    ~(run_driver_commands_in_new_processes : bool)
    : unit
  =
  let src_type =
    src_type
    |> Util.value_or_thunk ~default:(fun () ->
           EmitType.detect_exn ~path:src_path ~no_exe_extension)
  in
  let out_type =
    out_type
    |> Util.value_or_thunk ~default:(fun () ->
           match out_path with
           | Some out_path ->
               EmitType.detect_exn ~path:out_path ~no_exe_extension
           | None -> Exe)
  in
  let out_path =
    out_path
    |> Util.value_or_thunk ~default:(fun () ->
           let (dir_and_stem, _) = Filename.split_extension src_path in
           let ext = EmitType.extension out_type ~no_exe_extension in
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
    |> Util.value_or_thunk ~default:(fun () ->
           Filename.temp_dir (Filename.basename src_path) ".cstar")
  in
  let temps_dir =
    match temps_dir with
    | "" -> Filename.dirname out_path
    | _ -> temps_dir
  in
  let src_name =
    let base = Filename.basename src_path in
    let (stem, _) = Filename.split_extension base in
    stem
  in
  let temp_path emit_type =
    Filename.concat
      temps_dir
      (src_name ^ EmitType.extension emit_type ~no_exe_extension)
  in

  let raw_compile_args =
    range ~min:(EmitType.to_enum src_type) ~max:(EmitType.to_enum out_type)
    |> List.map ~f:(fun i ->
           (EmitType.of_enum_exn i, EmitType.of_enum_exn (i + 1)))
    |> List.map ~f:(fun (src, out) ->
           {
             src_path =
               (if EmitType.equal src src_type then src_path else temp_path src)
           ; src_type = src
           ; out_path =
               (if EmitType.equal out out_type then out_path else temp_path out)
           ; out_type = out
           })
  in

  if List.is_empty raw_compile_args
  then failwith "nothing to compile and cannot decompile";

  raw_compile_args
  |> List.iter ~f:(fun args ->
         run_raw_compile
           ~args
           ~print:print_driver_commands
           ~in_new_process:run_driver_commands_in_new_processes);

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
            (optional EmitType.arg)
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
            (optional EmitType.arg)
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
        and exe_extension =
          flag
            "--exe-extension"
            no_arg
            ~doc:"exe-extension use a `.cstar.exe` extension for executables"
        and run_driver_commands_in_new_processes =
          flag
            "--run-driver-commands-in-new-processes"
            no_arg
            ~doc:"run-driver-commands-in-new-processes as it says"
        in
        fun () ->
          compile_file
            ~src_path
            ~src_type
            ~out_path
            ~out_type
            ~temps_dir
            ~print_driver_commands
            ~no_exe_extension:(not exe_extension)
            ~run_driver_commands_in_new_processes)
  in
  let compile_raw =
    Command.basic
      ~summary:
        "compile a single stage of a C* source file; this is what the driver \
         invokes"
      Command.Let_syntax.(
        let%map_open src_path =
          flag "--src" (required Filename.arg_type) ~doc:"src src file"
        and src_type =
          flag
            "--src-type"
            (required EmitType.arg)
            ~doc:"src-type type of source if not inferred"
        and out_path =
          flag "--output" (required Filename.arg_type) ~doc:"output output file"
        and out_type =
          flag
            "--out-type"
            (required EmitType.arg)
            ~doc:"out-type what to output/emit"
        in
        fun () ->
          compile_file_raw ~args:{src_path; src_type; out_path; out_type})
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

let run () : unit = make_cmd () |> Command.run ~version:"0.1" ~build_info:""
