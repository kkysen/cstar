type publicity =
  | Public
  | PublicIn of string
  | Private
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

and named_type = {
  type_name : string
}
[@@deriving show, yojson]

and pointer_type = {
  pointee : type_
  ; mutability : mutability
}
[@@deriving show, yojson]

and reference_type = {
  referent : type_
  ; mutability : mutability
}
[@@deriving show, yojson]

and slice_type = {
  element_type : type_
}
[@@deriving show, yojson]

and array_type = {
  element_type : type_
  ; array_length : expr
}
[@@deriving show, yojson]

and tuple_type = {
  elements : type_ list
}
[@@deriving show, yojson]

and func_type = {
    args : tuple_type
  ; return_type : type_
}
[@@deriving show, yojson]

and generic_type = {
    name : string
  ; args : tuple_type
}
[@@deriving show, yojson]

and type_ =
  | InferredType
  | NamedType of named_type
  | PointerType of pointer_type
  | ReferenceType of reference_type
  | SliceType of slice_type
  | ArrayType of array_type
  | TupleType of tuple_type (* empty () is the unit type *)
  | FuncType of func_type
  | GenericType of generic_type
[@@deriving show, yojson]

type pattern = 
| IdentifierPattern of string * mutability
| NumPattern of number_literal
| CharPattern of char_literal
| StringPattern of string_literal
| RestPattern
[@@deriving show, yojson]

type arithmetic_binary_op =
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
[@@deriving show, yojson]

type comparison_op =
  | Equal
  | NotEqual
  | LessThan
  | LessThanOrEqual
  | GreaterThan
  | GreaterThanOrEqual
[@@deriving show, yojson]

type binary_op =
  | ArithmeticBinaryOp of arithmetic_binary_op
  | AssigningArithmeticBinaryOp of arithmetic_binary_op
  | ComparisonOp of comparison_op
  | Assign
[@@deriving show, yojson]

[@@@warning "-39"] (* from yojson *)
type mutability = {mut : bool} [@@deriving show, yojson]
[@@@warning "+39"]

type label = {name : string} [@@deriving show, yojson]

type unary_op =
  | Negate (* - *)
  | Not (* ! *)
  | BitNot (* ~ *)
[@@deriving show, yojson]

type if_expr = {
    then_case : block_expr
  ; else_case : block_expr option
}
[@@deriving show, yojson]

and match_arm = {
    match_pattern : pattern
  ; match_condition : expr option
  ; match_arm_value : expr
}
[@@deriving show, yojson]

and match_expr = {
    match_arms : match_arm list
}
[@@deriving show, yojson]

and for_expr = {
    for_element : variable
  ; for_block : block_expr
  ; for_label : label option
}
[@@deriving show, yojson]

and statement = 
  | Expr of expr
  | Item of item
[@@deriving show, yojson]

and block_expr = {
    statements : statement list
  ; trailing_semicolon : bool
}
[@@deriving show, yojson]

and func_call_expr = {
    func : expr
  ; generic_args : type_ list
  ; args : expr list
}
[@@deriving show, yojson]

and anon_func_signature = {
    args : variables
  ; return_type : type_
}
[@@deriving show, yojson]

and func_literal = {
    anon_signature : func_signature
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

and struct_literal_field = 
| Explicit of string * expr
| Implicit of string
| Spread of expr
[@@deriving show, yojson]

and struct_literal = {
    struct_name : string
  ; struct_fields : struct_field list
}
[@@deriving show, yojson]

and tuple_literal = {elements : expr list} [@@deriving show, yojson]

and sign = 
  | Plus
  | Minus
[@@deriving show, yojson]

and range_options = {
    inclusive : bool
  ; sign : sign option (* e.x. start..+length *)
}[@@deriving show, yojson]

(* TODO format_string_literal *)
and range_literal = {
    start : expr option
  ; stop : expr option
  ; options : range_options
}
[@@deriving show, yojson]

and literal =
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

and goto_kw =
  | Return
  | Break
  | Continue
[@@deriving show, yojson]

and postfix_expr =
  | Dereference of mutability (* .* *)
  | Reference of mutability (*.&, .&mut *)
  | Try (* .? *)
  | BinaryOp of binary_op
  | FieldAccess of string
  | ElementAccess of number_literal
  | MethodCall of func_call_expr
  | GoTo of label option * goto_kw
  | Defer of label option
  | Match of match_expr
  | If of if_expr
  | While of block_expr
  | For of for_expr
[@@deriving show, yojson]

and expr =
  | Variable of string
  | Literal of literal
  | UnaryOp of unary_expr
  | BinaryOp of binary_expr
  | Index of expr
  | FuncCall of func_call_expr
  | PostFixExpr of expr * postfix_expr
  | UnDefer of label option
  | Block of block_expr
[@@deriving show, yojson]

type annotation = {
    path : path
  ; args : tuple_literal
}
[@@deriving show, yojson]

type doc_comment = {lines : string list} [@@deriving show, yojson]

type variable = {
    name : string
  ; mutability : mutability
  ; type_ : type_
}
[@@deriving show, yojson]

type variable_with_metadata = {
    variable : variable
  ; metadata : metadata
}
[@@deriving show, yojson]

type variables = variable_with_metadata list

type let_ = {
    variable : variable
  ; value : expr
}
[@@deriving show, yojson]

type func_decl_signature = {
    name : string
  ; func_type : func_type
}
[@@deriving show, yojson]

type func_decl = {
    signature : func_decl_signature
  ; func_value : expr option
}
[@@deriving show, yojson]

type fields = variables

type struct_decl = {
    name : string
  ; fields : fields
}
[@@deriving show, yojson]

type variant_data = 
  | TupleVariant of tuple_type
  | StructVariant of fields
[@@deriving show, yojson]

type variant = {
    name : string
  ; data : variant_data option
}
[@@deriving show, yojson]

type enum_decl = {
    name : string
  ; variants : variant list
}
[@@deriving show, yojson]

type union_decl = {
    name : string
  ; fields : variables
}
[@@deriving show, yojson]

type use = {
  use_path : path
}
[@@deriving show, yojson]

type inner_item =
  | Use of use
  | Let of let_
  | FuncDecl of func_decl
  | StructDecl of struct_decl
  | EnumDecl of enum_decl
  | UnionDecl of union_decl
  | Impl of module_
  | Mod of module_
[@@deriving show, yojson]

type metadata = {
    publicity : publicity
  ; annotations : annotations
  ; doc_comment : doc_comment
}
[@@deriving show, yojson]

type item = {
    metadata : metadata
  ; inner_item : inner_item
}
[@@deriving show, yojson]

type module_body = {
  items : item list
}
[@@deriving show, yojson]

type module_ = {
    name : string
  ; body : module_body
}
[@@deriving show, yojson]

type ast = {
    path : string
  ; module_ : module_
}
[@@deriving show, yojson]

(* type tuple = {
  elements : 
}
[@@deriving show, yojson] *)
