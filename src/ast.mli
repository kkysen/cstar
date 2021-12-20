type publicity =
  | Public
  | PublicIn of string
  | Private
[@@deriving show, yojson]

[@@@warning "-39"] (* from yojson *)
type mutability = {mut : bool} [@@deriving show, yojson]
[@@@warning "+39"]

type doc_comment = {lines : string list} [@@deriving show, yojson]

type label = {label_name : string} [@@deriving show, yojson]

type number_literal = Token.number_literal [@@deriving show, yojson]

type char_literal = Token.char_literal [@@deriving show, yojson]

type string_literal = Token.string_literal [@@deriving show, yojson]

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

type unary_op =
  | Negate (* - *)
  | Not (* ! *)
  | BitNot (* ~ *)
[@@deriving show, yojson]

type sign = 
  | Plus
  | Minus
[@@deriving show, yojson]

type range_options = {
    inclusive : bool
  ; sign : sign option (* e.x. start..+length *)
}[@@deriving show, yojson]

type goto_kw =
  | Return
  | Break
  | Continue
[@@deriving show, yojson]

type path = {
    path_pars : string list
}
[@@deriving show, yojson]

type use = {
  use_path : path
}
[@@deriving show, yojson]

type named_type = {
  type_name : string
}
[@@deriving show, yojson]

and pointer_type = {
  pointee : type_
  ; pointer_mutability : mutability
}
[@@deriving show, yojson]

and reference_type = {
  referent : type_
  ; reference_mutability : mutability
}
[@@deriving show, yojson]

and slice_type = {
  slice_element_type : type_
}
[@@deriving show, yojson]

and array_type = {
  array_element_type : type_
  ; array_length : expr
}
[@@deriving show, yojson]

and tuple_type = {
  elements : type_ list
}
[@@deriving show, yojson]

and func_type = {
    func_args : tuple_type
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

and pattern = 
| IdentifierPattern of string * mutability
| NumPattern of number_literal
| CharPattern of char_literal
| StringPattern of string_literal
| RestPattern
[@@deriving show, yojson]

and if_expr = {
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
  ; call_generic_args : type_ list
  ; call_args : expr list
}
[@@deriving show, yojson]

and anon_func_signature = {
    signature_args : variables
  ; signature_return_type : type_
}
[@@deriving show, yojson]

and func_literal = {
    anon_signature : anon_func_signature
  ; func_literal_value : expr
}
[@@deriving show, yojson]

and closure_literal = {
    closure_context : struct_literal
  ; closure_func : func_literal
}
[@@deriving show, yojson]

and struct_literal_field = 
| Explicit of string * expr
| Implicit of string
| Spread of expr
[@@deriving show, yojson]

and struct_literal = {
    struct_literal_name : string
  ; struct_literal_fields : struct_literal_field list
}
[@@deriving show, yojson]

and tuple_literal = {
  tuple_elements : expr list
} [@@deriving show, yojson]

and array_literal = {
  array_elements : expr list
} [@@deriving show, yojson]

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
  | Array of array_literal
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

and postfix_expr =
  | Dereference of mutability (* .* *)
  | Reference of mutability (*.&, .&mut *)
  | Try (* .? *)
  | PostFixBinaryOp of binary_op
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

and annotation = {
    annotation_path : path
  ; annotation_args : tuple_literal
}
[@@deriving show, yojson]

and metadata = {
    publicity : publicity
  ; annotations : annotation list
  ; doc_comment : doc_comment
}
[@@deriving show, yojson]

and variable = {
    variable_name : string
  ; variable_mutability : mutability
  ; variable_type : type_
}
[@@deriving show, yojson]

and variable_with_metadata = {
    variable : variable
  ; metadata : metadata
}
[@@deriving show, yojson]

and variables = variable_with_metadata list

and let_ = {
    let_variable : variable
  ; let_value : expr
}
[@@deriving show, yojson]

and func_decl_signature = {
    func_name : string
  ; func_signature : anon_func_signature
}
[@@deriving show, yojson]

and func_decl = {
    func_decl_signature : func_decl_signature
  ; func_value : expr option
}
[@@deriving show, yojson]

and fields = variables

and struct_decl = {
    struct_name : string
  ; struct_fields : fields
}
[@@deriving show, yojson]

and variant_data = 
  | TupleVariant of tuple_type
  | StructVariant of fields
[@@deriving show, yojson]

and variant = {
    variant_name : string
  ; variant_data : variant_data option
}
[@@deriving show, yojson]

and enum_decl = {
    enum_name : string
  ; enum_variants : variant list
}
[@@deriving show, yojson]

and union_decl = {
    union_name : string
  ; union_fields : variables
}
[@@deriving show, yojson]

and inner_item =
  | Use of use
  | Let of let_
  | FuncDecl of func_decl
  | StructDecl of struct_decl
  | EnumDecl of enum_decl
  | UnionDecl of union_decl
  | Impl of module_
  | Mod of module_
[@@deriving show, yojson]

and item = {
    item_metadata : metadata
  ; inner_item : inner_item
}
[@@deriving show, yojson]

and module_body = {
  module_items : item list
}
[@@deriving show, yojson]

and module_ = {
    module_name : string
  ; module_body : module_body
}
[@@deriving show, yojson]

type ast = {
    path : string
  ; module_ : module_
}
[@@deriving show, yojson]
