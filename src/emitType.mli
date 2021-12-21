open Core

type t =
  | Src
  | Tokens
  | Ast
  | DesugaredAst
  | TypedAst
  | Lir
  | Ir
  | Bc
  | Asm
  | Obj
  | Exe
[@@deriving show, eq, ord, enum]

val of_enum_exn : int -> t

val all : t list

val to_string : t -> string

val of_string : string -> t

val extension : t -> no_exe_extension:bool -> string

val detect : path:string -> no_exe_extension:bool -> t option

val detect_exn : path:string -> no_exe_extension:bool -> t

val is_llvm : t -> bool

val arg : t Command.Arg_type.t
