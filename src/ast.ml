type publicity =
  | Public
  | PublicIn of string
  | Private
[@@deriving show]

type int_bits =
  | Exact of int
  | Size
  | Ptr
[@@deriving show]

type int_type = {
    unsigned : bool
  ; bits : int_bits
}
[@@deriving show]

type float_type = {bits : int} [@@deriving show]

type char_type = {byte : bool} [@@deriving show]

type string_type = {
    byte : bool
  ; raw : bool
  ; c : bool
}
[@@deriving show]

type primitive_type =
  | Unit
  | Int of int_type
  | Float of float_type
  | Char of char_type
  | String of string_type
[@@deriving show]

type field_type = {
    field_name : string
  ; field_type : type_
  ; publicity : publicity
}
[@@deriving show]

(* tuples are just structs with whole number field names *)
and struct_type = {
    struct_name : string
  ; struct_fields : field_type StringMap.t
}
[@@deriving show]

and element_type = {
    element_index : int
  ; element_type : type_
}
[@@deriving show]

and tuple_type = {elements : element_type list} [@@deriving show]

and variant_type = {
    variant_name : string
  ; variant_type : type_
}
[@@deriving show]

and enum_type = {
    enum_name : string
  ; enum_variants : variant_type StringMap.t
}
[@@deriving show]

and union_type = {
    union_name : string
  ; union_fields : field_type StringMap.t
}
[@@deriving show]

and generic_type = {
    generic_name : string
  ; generic_bounds : type_ list
}
[@@deriving show]

and variable = {
    variable_name : string
  ; variable_type : type_
}
[@@deriving show]

and func_type = {
    func_name : string
  ; generic_args : generic_type StringMap.t
  ; args : variable StringMap.t
  ; return_type : type_
}
[@@deriving show]

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
[@@deriving show]

type pattern = unit (* TODO *) [@@deriving show]

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
[@@deriving show]

type pointer_to = {mut : bool} [@@deriving show]

and label = {name : string} [@@deriving show]

type unary_op =
  | Negate (* - *)
  | Not (* ! *)
  | BitNot (* ~ *)
  | Dereference (* .* *)
  | PointerTo of pointer_to (*.&, .&mut *)
  | Try (* .? *)
[@@deriving show]

type if_expr = {
    if_condition : expr
  ; if_then_case : block_expr
}
[@@deriving show]

and if_else_expr = {
    if_else_condition : expr
  ; if_else_then_case : block_expr
  ; if_else_else_case : block_expr
}
[@@deriving show]

and match_arm = {
    match_pattern : pattern
  ; match_condition : expr option
  ; match_arm_value : expr
}
[@@deriving show]

and match_expr = {
    match_value : expr
  ; match_arms : match_arm list
}
[@@deriving show]

(* TODO might change*)
and for_expr = {
    for_initializer_ : expr
  ; for_condition : expr
  ; for_update : expr
  ; for_block : block_expr
}
[@@deriving show]

and while_expr = {
    while_condition : expr
  ; while_block : block_expr
}
[@@deriving show]

and block_expr = {
    statements : expr list
  ; trailing_semicolon : bool
}
[@@deriving show]

and field_access_expr = {
    obj : expr option (* None if variable instead of field access *)
  ; field : string
}
[@@deriving show]

and func_call_expr = {
    func : expr
  ; generic_args : type_ list
  ; args : expr list
  ; self_arg : expr option (* for methods *)
}
[@@deriving show]

and func_literal = {
    func_type : func_type
  ; func_value : expr
}
[@@deriving show]

and closure_literal = {
    closure_context : struct_literal
  ; closure_func : func_literal
}
[@@deriving show]

and number_literal = Token.number_literal

and char_literal = Token.char_literal

and string_literal = Token.string_literal

and struct_literal = {
    struct_name : string
  ; struct_spread : bool (* .. *)
  ; struct_fields : expr option StringMap.t
        (* None if field name is same as expr *)
}
[@@deriving show]

and tuple_literal = {elements : expr list} [@@deriving show]

(* TODO format_string_literal *)
and range_literal = {
    start : expr option
  ; stop : expr option
  ; inclusive : bool
  ; additive : bool (* start..+length *)
}
[@@deriving show]

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
[@@deriving show]

and unary_expr = {
    unary_op : unary_op
  ; unary_value : expr
}
[@@deriving show]

and binary_expr = {
    binary_op : binary_op
  ; left : expr
  ; right : expr
}
[@@deriving show]

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
[@@deriving show]

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

type  stmt = Block of stmt list | Expr of expr
| Return of expr
| If of expr * stmt * stmt
| For of expr * expr * expr * stmt | While of expr * stmt

type annotation_arg = unit (* TODO *) [@@deriving show]

type annotation = {
    name : string
  ; args : annotation_arg list
}
[@@deriving show]

type doc_comment = {lines : string list} [@@deriving show]

type let_binding = {
    name : string
  ; publicity : publicity
  ; annotations : annotation list
  ; doc_comment : doc_comment
}
[@@deriving show]

type value_let = {
    binding : let_binding
  ; value : expr
}
[@@deriving show]

type type_let = {
    binding : let_binding
  ; value : type_
}
[@@deriving show]

type func_decl = {
    binding : let_binding
  ; func : func_literal
}
[@@deriving show]

type impl = {
    impl_type : type_
  ; impl_funcs : func_decl StringMap.t
}
[@@deriving show]

type let_ =
  | Value of value_let
  | Type of type_let
[@@deriving show]

type item =
  | Let of let_
  | Impl of impl
[@@deriving show]

type module_ = {
    name : string
  ; items : item list
}
[@@deriving show]

type ast = {module_ : module_} [@@deriving show]
