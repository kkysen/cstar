(* In LIR (low-level cstar IR), everything is monomorphized and all symbols,
   globals and functions, have unique names now.

   Platform-dependent types like usize have been expanded. Types and other
   semantic analyses are all checked by now. Everything is now mutable.
   References are now pointers, slices are structs structs are now tuples (llvm
   aggregate types), TODO enums unions.

   `main` is guaranteed to be defined.*)

type int_type = {
    bits : int
  ; unsigned : bool
}
[@@deriving yojson]

type float_type =
  | F32
  | F64
[@@deriving yojson]

type func_type = {
    func_args : type_ array
  ; func_return_type : type_
}
[@@deriving yojson]

and type_ =
  | UnitType
  | IntType of int_type
  | FloatType of float_type
  | PointerType of type_
  | ArrayType of type_ * int
  | TupleType of type_ array
  | FuncType of func_type
[@@deriving yojson]

type literal =
  | Int of int
  | Float of float
[@@deriving yojson]

type global = {
    global_name : string
  ; global_type : type_
  ; global_value : literal option
}
[@@deriving yojson]

type unary_op =
  | Negate
  | Not
  | BitNot
  | AddressOf
  | Dereference
[@@deriving yojson]

type binary_op =
  | Assign
  | Add
  | Subtract
  | Multiply
  | Divide
  | Modulo
  | And
  | Or
  | BitAnd
  | BitOr
  | BitXor
  | LeftShift
  | RightShift
  | Equal
  | NotEqual
  | LessThan
  | LessThanOrEqual
  | GreaterThan
  | GreaterThanOrEqual
[@@deriving yojson]

type label = string [@@deriving yojson]

type call_expr = {
    callee : expr
  ; call_args : expr array
}
[@@deriving yojson]

and if_expr = {
    condition : expr
  ; then_case : expr
  ; else_case : expr
}
[@@deriving yojson]

and raw_expr =
  | Literal of literal
  | Var of string
  | UnaryOp of unary_op * expr
  | BinaryOp of expr * binary_op * expr
  | Cast of expr
  | Call of call_expr
  | If of if_expr
  | GoTo of expr
  | Block of expr list
[@@deriving yojson]

and expr = {
    type_ : type_
  ; value : raw_expr
}
[@@deriving yojson]

type func_decl = {
    arg_names : string array
  ; func_value : expr
}
[@@deriving yojson]

type func = {
    func_name : string
  ; func_type : func_type
  ; func_decl : func_decl option
}
[@@deriving yojson]

type lir = {
    path : string
  ; globals : global list
  ; functions : func list
}
[@@deriving yojson]
