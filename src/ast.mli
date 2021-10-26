module StringMap : Map.S with type key = string

type publicity =
  | Public
  | PublicIn of string
  | Private

type int_bits =
  | Exact of int
  | Size
  | Ptr

type int_type = {
    unsigned : bool
  ; bits : int_bits
}

type float_type = {bits : int}

type char_type = {byte : bool}

type string_type = {
    byte : bool
  ; raw : bool
  ; c : bool
}

type primitive_type =
  | Unit
  | Int of int_type
  | Float of float_type
  | Char of char_type
  | String of string_type

type field_type = {
    name : string
  ; type_ : type_
  ; publicity : publicity
}

(* tuples are just structs with whole number field names *)
and struct_type = {
    name : string
  ; fields : field_type StringMap.t
}

and variant_type = {
    name : string
  ; type_ : type_
}

and enum_type = {
    name : string
  ; variants : variant_type StringMap.t
}

and union_type = {
    name : string
  ; fields : field_type StringMap.t
}

and generic_type = {
    name : string
  ; bounds : type_ list
}

and variable = {
    name : string
  ; type_ : type_
}

and func_type = {
    name : string
  ; abi : string
  ; generic_args : generic_type StringMap.t
  ; args : variable StringMap.t
}

and type_ =
  | Inferred
  | Primitive of primitive_type
  | Struct of struct_type
  | Enum of enum_type
  | Union of union_type
  | Func of func_type

type pattern = unit (* TODO *)

type binary_op =
  | SemiColon
  | Add
  | Subtract
  | Multiply
  | Divide
  | Modulo
  | Equal
  | NotEqual
  | LessThan
  | LessThanOrEqual
  | GreaterThan
  | GreaterThanOrEqual
  | And
  | Or
  | BitAnd
  | BitOr
  | BitXor

type unary_op =
  | Negate
  | Not
  | BitNot

type if_expr = {
    condition : expr
  ; then_case : block_expr
}

and if_else_expr = {
    condition : expr
  ; then_case : block_expr
  ; else_case : block_expr
}

and match_arm = {
    pattern : pattern
  ; condition : expr option
  ; value : expr
}

and match_expr = {
    value : expr
  ; arms : match_arm list
}

(* TODO might change*)
and for_expr = {
    initializer_ : expr
  ; condition : expr
  ; update : expr
  ; block : block_expr
}

and while_expr = {
    condition : expr
  ; block : block_expr
}

and block_expr = {value : expr}

and func_call_expr = {
    func_name : string
  ; generic_args : type_ list
  ; args : expr list
  ; self_arg : expr option (* for methods *)
}

and expr =
  | Assign of string * expr
  | UnaryOp of unary_op * expr
  | BinaryOp of expr * binary_op * expr
  | Lit of int
  | Var of string
  | Match of match_expr
  | Defer of expr
  | Return of expr
  | If of if_expr
  | IfElse of if_else_expr
  | For of for_expr
  | While of while_expr
  | Block of block_expr
  | FuncCall of func_call_expr

type func = {
    type_ : type_
  ; expr : expr
}

type annotation_arg = unit (* TODO *)

type annotation = {
    name : string
  ; args : annotation_arg list
}

type doc_comment = {lines : string list}

type let_binding = {
    name : string
  ; publicity : publicity
  ; annotations : annotation list
  ; doc_comment : doc_comment
}

type value_let = {
    binding : let_binding
  ; value : expr
}

type type_let = {
    binding : let_binding
  ; value : type_
}

type impl = {
    type_ : type_
  ; functions : func StringMap.t
}

type let_ =
  | Value of value_let
  | Type of type_let

type item =
  | Let of let_
  | Impl of impl

type module_ = {
    name : string
  ; items : item list
}
