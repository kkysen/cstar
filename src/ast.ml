type publicity =
  | Public
  | PublicIn of string
  | Private
[@@deriving show, yojson]

type int_bits =
  | Exact of int
  | Size
  | Ptr
[@@deriving show, yojson]

type int_type = {
    unsigned : bool
  ; bits : int_bits
}
[@@deriving show, yojson]

type float_type = {bits : int} [@@deriving show, yojson]

type char_type = {byte : bool} [@@deriving show, yojson]

type string_type = {
    byte : bool
  ; raw : bool
  ; c : bool
}
[@@deriving show, yojson]

type primitive_type =
  | Unit
  | Int of int_type
  | Float of float_type
  | Char of char_type
  | String of string_type
[@@deriving show, yojson]

type field_type = {
    field_name : string
  ; field_type : type_
  ; publicity : publicity
}
[@@deriving show, yojson]

(* tuples are just structs with whole number field names *)
and struct_type = {
    struct_name : string
  ; struct_fields : field_type StringMap.t
}
[@@deriving show, yojson]

and element_type = {
    element_index : int
  ; element_type : type_
}
[@@deriving show, yojson]

and tuple_type = {elements : element_type list} [@@deriving show, yojson]

and variant_type = {
    variant_name : string
  ; variant_type : type_
}
[@@deriving show, yojson]

and enum_type = {
    enum_name : string
  ; enum_variants : variant_type StringMap.t
}
[@@deriving show, yojson]

and union_type = {
    union_name : string
  ; union_fields : field_type StringMap.t
}
[@@deriving show, yojson]

and generic_type = {
    generic_name : string
  ; generic_bounds : type_ list
}
[@@deriving show, yojson]

and variable = {
    variable_name : string
  ; variable_type : type_
}
[@@deriving show, yojson]

and func_type = {
    func_name : string
  ; generic_args : generic_type StringMap.t
  ; args : variable StringMap.t
  ; return_type : type_
}
[@@deriving show, yojson]

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
  | Self
[@@deriving show, yojson]

type pattern = unit (* TODO *) [@@deriving show, yojson]

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
[@@deriving show, yojson]

[@@@warning "-39"] (* from yojson *)
type pointer_to = {mut : bool} [@@deriving show, yojson]
[@@@warning "+39"]

type label = {name : string} [@@deriving show, yojson]

type unary_op =
  | Negate (* - *)
  | Not (* ! *)
  | BitNot (* ~ *)
  | Dereference (* .* *)
  | PointerTo of pointer_to (*.&, .&mut *)
  | Try (* .? *)
[@@deriving show, yojson]

type if_expr = {
    if_condition : expr
  ; if_then_case : block_expr
}
[@@deriving show, yojson]

and if_else_expr = {
    if_else_condition : expr
  ; if_else_then_case : block_expr
  ; if_else_else_case : block_expr
}
[@@deriving show, yojson]

and match_arm = {
    match_pattern : pattern
  ; match_condition : expr option
  ; match_arm_value : expr
}
[@@deriving show, yojson]

and match_expr = {
    match_value : expr
  ; match_arms : match_arm list
}
[@@deriving show, yojson]

(* TODO might change*)
and for_expr = {
    for_initializer_ : expr
  ; for_condition : expr
  ; for_update : expr
  ; for_block : block_expr
}
[@@deriving show, yojson]

and while_expr = {
    while_condition : expr
  ; while_block : block_expr
}
[@@deriving show, yojson]

and block_expr = {
    statements : expr list
  ; trailing_semicolon : bool
}
[@@deriving show, yojson]

and field_access_expr = {
    obj : expr option (* None if variable instead of field access *)
  ; field : string
}
[@@deriving show, yojson]

and func_call_expr = {
    func : expr
  ; generic_args : type_ list
  ; args : expr list
  ; self_arg : expr option (* for methods *)
}
[@@deriving show, yojson]

and func_literal = {
    func_type : func_type
  ; func_value : expr
}
[@@deriving show, yojson]

and closure_literal = {
    closure_context : struct_literal
  ; closure_func : func_literal
}
[@@deriving show, yojson]

and number_literal = Token.number_literal

and char_literal = Token.char_literal

and string_literal = Token.string_literal

and struct_literal = {
    struct_name : string
  ; struct_spread : bool (* .. *)
  ; struct_fields : expr option StringMap.t
        (* None if field name is same as expr *)
}
[@@deriving show, yojson]

and tuple_literal = {elements : expr list} [@@deriving show, yojson]

(* TODO format_string_literal *)
and range_literal = {
    start : expr option
  ; stop : expr option
  ; inclusive : bool
  ; additive : bool (* start..+length *)
}
[@@deriving show, yojson]

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
[@@deriving show, yojson]

and unary_expr = {
    unary_op : unary_op
  ; unary_value : expr
}
[@@deriving show, yojson]

and binary_expr = {
    binary_op : binary_op
  ; left : expr
  ; right : expr
}
[@@deriving show, yojson]

and expr =
  | Literal of literal
  | UnaryOp of unary_expr
  | BinaryOp of binary_expr
  | Return of expr * label
  | Break of expr * label
  | Continue of expr * label
  | Match of match_expr
  | Defer of expr * label
  | UnDefer of label
  | If of if_expr
  | IfElse of if_else_expr
  | For of for_expr
  | While of while_expr
  | FuncCall of func_call_expr
  | Block of block_expr
  (* includes variables *)
  | FieldAccess of field_access_expr
[@@deriving show, yojson]

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

type annotation_arg = unit (* TODO *) [@@deriving show, yojson]

type annotation = {
    name : string
  ; args : annotation_arg list
}
[@@deriving show, yojson]

type doc_comment = {lines : string list} [@@deriving show, yojson]

type let_binding = {
    name : string
  ; publicity : publicity
  ; annotations : annotation list
  ; doc_comment : doc_comment
}
[@@deriving show, yojson]

type value_let = {
    binding : let_binding
  ; value : expr
}
[@@deriving show, yojson]

type type_let = {
    binding : let_binding
  ; value : type_
}
[@@deriving show, yojson]

type func_decl = {
    binding : let_binding
  ; func : func_literal
}
[@@deriving show, yojson]

type impl = {
    impl_type : type_
  ; impl_funcs : func_decl StringMap.t
}
[@@deriving show, yojson]

type let_ =
  | Value of value_let
  | Type of type_let
[@@deriving show, yojson]

type item =
  | Let of let_
  | Impl of impl
[@@deriving show, yojson]

type module_ = {
    name : string
  ; items : item list
}
[@@deriving show, yojson]

type ast = {
    path : string
  ; module_ : module_
}
[@@deriving show, yojson]

