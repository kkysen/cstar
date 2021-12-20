type raw_compile_args = {
    src_path : string
  ; src_type : EmitType.t
  ; out_path : string
  ; out_type : EmitType.t
}
[@@deriving show]

val compile_file_raw : args:raw_compile_args -> unit

val compile_file
  :  src_path:string
  -> src_type:EmitType.t option
  -> out_path:string option
  -> out_type:EmitType.t option
  -> temps_dir:string option
  -> print_driver_commands:bool
  -> no_exe_extension:bool
  -> run_driver_commands_in_new_processes:bool
  -> unit

val run : unit -> unit
