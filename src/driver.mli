type emit_type =
  | Src
  (* | Ast *)
  | Ir
  | Bc
  | Asm
  | Obj
  | Exe
[@@deriving show, eq, ord, enum]

val compile_file_raw : src_path:string -> src_type:emit_type -> out_path:string -> out_type:emit_type -> unit

val compile_file : src_path:string -> src_type:emit_type option -> out_path:string option -> out_type:emit_type option -> temps_dir:string option -> print_driver_commands:bool -> unit

val run : unit -> unit
