open Core

type t =
  | Src
  | Tokens
  | Ast
  | DesugaredAst
  | TypedAst
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

val extension : t -> string

val detect : path:string -> t option

val detect_exn : path:string -> t

val is_llvm : t -> bool

val arg : t Command.Arg_type.t
