val compile_file_raw : src_path:string -> src_type:EmitType.t -> out_path:string -> out_type:EmitType.t -> unit

val compile_file : src_path:string -> src_type:EmitType.t option -> out_path:string option -> out_type:EmitType.t option -> temps_dir:string option -> print_driver_commands:bool -> unit

val run : unit -> unit
