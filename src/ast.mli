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

and element_type = {
    index : int
  ; type_ : type_
}

and tuple_type = {elements : element_type list}

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
  ; generic_args : generic_type StringMap.t
  ; args : variable StringMap.t
}

and type_ =
  | Inferred
  | Primitive of primitive_type
  | Struct of struct_type
  | Tuple of tuple_type
  | Enum of enum_type
  | Union of union_type
  | Func of func_type
  | Pointer of type_
  | Slice of type_

type pattern = unit (* TODO *)

type binary_op =
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
  | Assign

type pointer_to = {mut : bool}

and label = {name : string}

type unary_op =
  | Negate (* - *)
  | Not (* ! *)
  | BitNot (* ~ *)
  | Dereference (* .* *)
  | PointerTo of pointer_to (*.&, .&mut *)
  | Try
(* .? *)

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

and block_expr = {
    statements : expr list
  ; trailing_semicolon : bool
}

and field_access_expr = {
    obj : expr option (* None if variable instead of field access *)
  ; field : string
}

and func_call_expr = {
    func : expr
  ; generic_args : type_ list
  ; args : expr list
  ; self_arg : expr option (* for methods *)
}

and func_literal = {
    type_ : func_type
  ; value : expr
  ; extern : bool
}

and closure_literal = {
    context : struct_literal
  ; func : func_literal
}

and number_literal = Token.number_literal

and char_literal = Token.char_literal

and string_literal = Token.string_literal

and struct_literal = {
    name : string
  ; spread : bool (* .. *)
  ; fields : expr option StringMap.t (* None if field name is same as expr *)
}

and tuple_literal = {elements : expr list}

(* TODO format_string_literal *)
and range_literal = {
    start : expr option
  ; stop : expr option
  ; inclusive : bool
  ; additive : bool (* start..+length *)
}

and literal =
  | Unit
  | Bool of bool
  | Number of number_literal
  | Char of char_literal
  | String of string_literal
  | Range of range_literal
  | Struct of struct_literal
  | Tuple of tuple_literal
  | Func of func_literal
  | Closure of closure_literal

and unary_expr = {
    op : unary_op
  ; value : expr
}

and binary_op = {
    op : binary_op
  ; left : expr
  ; right : expr
}

and return_expr = {
    value : expr
  ; label : option label
}

and break_expr = {
    value : expr
  ; label : option label
}

and continue_expr = {
    value : expr (* not allowed as of now but maybe later? *)
  ; label : option label
}

and defer_expr = {
    value : expr
  ; label : option label
}

and un_defer_expr = {label : label}

and expr =
  | Literal of liral
  | UnaryOp of unary_expr
  | BinaryOp of binary_expr
  | Return of return_expr
  | Break of break_expr
  | Continue of continue_expr
  | Match of match_expr
  | Defer of defer_expr
  | UnDefer of un_defer_expr
  | If of if_expr
  | IfElse of if_else_expr
  | For of for_expr
  | While of while_expr
  | FuncCall of func_call_expr
  | Block of block_expr
  (* includes variables *)
  | FieldAccess of field_access_expr

(* TODO where do labels go?
 * Should they be `'label:` like Rust?
 * Or could they be like this?
 *    for@label
 *    while@label
 *    break@label
 *    continue@label
 *    defer@label
 *    undefer@label
 * No space b/w keyword, @, and label name
 * I think I like that way most.
 *)

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

type func_decl = {
  func: func_literal;
}

type impl = {
    type_ : type_
  ; functions : func_decl StringMap.t
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
