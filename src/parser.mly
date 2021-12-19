%{ 
    open Ast
%}

%token EOF
%token <string> WhiteSpace
%token StructuralComment
%token <string> LineComment
%token <string> BlockComment
%token <string> Identifier
%token <Token.number_literal> NumLiteral
%token <Token.char_literal> CharLiteral
%token <Token.string_literal> StringLiteral
%token KwMod
%token KwUse
%token KwLet
%token KwMut
%token KwPub
%token KwTry
%token KwConst
%token KwImpl
%token KwFn
%token KwStruct
%token KwEnum
%token KwUnion
%token KwReturn
%token KwBreak
%token KwContinue
%token KwFor
%token KwWhile
%token KwIf
%token KwElse
%token KwMatch
%token KwDefer
%token KwUndefer
%token KwIn
%token KwSelf
%token KwTrait
%token SemiColon
%token Colon
%token Comma
%token Dot
%token DotDot
%token OpenParen
%token CloseParen
%token OpenBrace
%token CloseBrace
%token OpenBracket
%token CloseBracket
%token At
%token QuestionMark
%token ExclamationPoint
%token Equal
%token EqualEqual
%token NotEqual
%token LessThan
%token GreaterThan
%token LessThanOrEqual
%token GreaterThanOrEqual
%token LeftShift
%token RightShift
%token Arrow
%token Plus
%token Minus
%token Times
%token Divide
%token And
%token Or
%token AndAnd
%token OrOr
%token Caret
%token Percent
%token Tilde
%token Pound
%token DollarSign

%start module_body
%type <Ast.module_body> module_body

// TODO precedence

%nonassoc Equal
%nonassoc DotDot
%left OrOr
%left AndAnd
%nonassoc EqualEqual NotEqual LessThan GreaterThan LessThanOrEqual GreaterThanOrEqual
%left Or
%left Caret
%left And
%left LeftShift RightShift
%left Plus Minus
%left Times Divide Modulo
%left Dot

%%

// trailing comma required for 1-element tuple
tuple_elements:
| { [] }
| expr Comma expr { [$1; $3] }
| expr Comma tuple_elements { $1 :: $3 }

tuple:
| OpenParen tuple_elements CloseParen { }

array_elements_no_trailing_comma:
| expr { [$1] }
| expr Comma array_elements_no_trailing_comma { $1 :: $3 }

array_elements:
| { [] }
| expr { [$1] }
| expr Comma array_elements { $1 :: $3 }

array:
| OpenBracket array_elements CloseBracket {  }

struct_initializer:
| Identifier Colon expr { Explicit ($1, $3) }
| Identifier { Implicit $1 }
| DotDot expr { Spread $2 }

struct_initializers:
| { [] }
| struct_initializer { [$1] }
| struct_initializer Comma struct_initializers { $1 :: $3 }

struct:
| Identifier OpenBrace struct_initializers CloseBrace { {
    name = $1;
    fields = $3;
} }

range_op:
| DotDot { () }

range_options:
| { {inclusive = false; sign = None}}
| Equal { {inclusive = true; sign = None}}
| Plus { {inclusive = false; sign = Plus}}
| Plus Equal { {inclusive = true; sign = Plus}}
| Minus { {inclusive = false; sign = Minus}}
| Minus Equal { {inclusive = true; sign = Minus}}

range:
| expr range_op range_options expr { {start = $1; stop = $3; options = $2} }
| expr range_op range_options { {start = $1; stop = None; options = $2} }
| range_op range_options expr { {start = None; stop = $3; options = $2} }

literal:
| NumLiteral { Number $1 }
| CharLiteral { Char $1 }
| StringLiteral { String $1 }
| tuple { Tuple $1 }
| struct { Struct $1 }
| range { Range $1 }
// TODO { Func $1 }
// TODO { Closure $1 }

path:
| Identifier { [$1] }
| Identifier Dot path { $1 :: $3 }

publicity:
| { Private }
| KwPub { Public }
| KwPub OpenParen KwIn WhiteSpace path CloseParen { PublicIn $5 }

annotation:
| At path { {
    path = $2;
    args = [];
} }
| At path tuple { {
    path = $2;
    args = $3;
} }

annotations:
| { [] }
| annotation WhiteSpace annotations { $1 :: $2 }

metadata:
| annotations publicity { {
    publicity = $2;
    annotations = $1;
    doc_comments = {
        lines = [];
    };
} }

use:
| KwUse path SemiColon { {
    path = $2;
} }

mut:
| { {mut = false} }
| KwMut { {mut = true} }

type:
| OpenParen CloseParen { UnitType }
| Identifier { NamedType {
    type_name = $1;
} }
| type Times mut { PointerType {
    pointee = $1; 
    mutability = $3;
} }
| type And mut { ReferenceType {
    referent = $1; 
    mutability = $3;
} }
| type OpenBracket CloseBracket { SliceType {
    element_type = $1;
} }
// TODO: eventually allow length to be an expr if it's const
| type OpenBracket NumLiteral CloseBracket { ArrayType {
    element_type = $1; 
    array_length = Literal (Number $3);
} }
| tuple_type { $1 }
| KwFn tuple_type Colon type { FuncType {
    args = $2;
    return_type = $4;
} }
// TODO GenericType
| OpenParen type CloseParen { $2 } // as parentheses

// single-element tuple requires trailing comma
// but otherwise it's optional
inner_tuple_type:
| { [] }
| type Comma { [$1] }
| type Comma type { [$1; $3] }
| type Comma inner_tuple_type { $1 :: $3 }

tuple_type:
| OpenParen tuple_type CloseParen { TupleType {
    elements = $2;
} }

type_annotation:
| { InferredType }
| Colon type { $2 }

variable:
| mut Identifier type_annotation { {
    name = $2; 
    type_ = $3; 
    mutability = $1;
} }

meta_variable:
| metadata variable { {
    variable = $2;
    metadata = $1;
} }

let_:
| KwLet variable Equal expr SemiColon { {
    variable = $2;
    value = $4;
} }

unary_op:
| Minus { Negate }
| ExclamationPoint { Not }
| Tilde { BitNot }

arithmetic_binary_op:
| Plus { Add }
| Minus { Subtract }
| Times { Multiply }
| Divide { Divide }
| Percent { Modulo }
| AndAnd { And }
| OrOr { Or }
| And { BitAnd }
| Or { BitOr }
| Caret { BitXor }
| LeftShift { LeftShit }
| RightShift { RightShift }

comparison_op:
| EqualEqual { Equal }
| NotEqual { NotEqual }
| LessThan { LessThan }
| LessThanOrEqual { LessThanOrEqual }
| GreaterThan { GreaterThan }
| GreaterThanOrEqual { GreaterThanOrEqual }

binary_op:
| arithmetic_binary_op { ArithmeticBinaryOp $1 }
| arithmetic_binary_op Equal { AssigningArithmeticBinaryOp $1 }
| comparison_op { ComparisonOp $1 }
| Equal { Assign }

else:
| { None }
| KwElse block { Some $2 }

if:
| KwIf block else { {
    then_case = $2;
    else_case = $3;
} }

pattern:
| mut Identifier { IdentifierPattern ($2, $1) }
| NumLiteral { NumPattern $1 }
| CharLiteral { CharPattern $1 }
| StringLiteral { StringPattern $1 }
| DotDot { RestPattern }

pattern_condition:
| { None }
| KwIf WhiteSpace expr { Some $3 }

match_arm:
| pattern pattern_condition Arrow expr { {
    match_pattern = $1;
    match_condition = $2;
    match_arm_value = $4;
} }

match_arms:
| { [] } // empty match on empty enum (a never type) would be valid
| match_arm Comma { [$1] }
| match_arm Comma match_arms { $1 :: $3 }

match:
| KwMatch OpenBrace match_arms CloseBrace { {
    match_arms = $3;
} }

label:
| WhiteSpace { None }
| At Identifier WhiteSpace { Some {name = $2} }

goto_kw:
| KwReturn {  }
| KwBreak {  }
| KwContinue {  }

postfix_expr:
| Times mut { Dereference $2 }
| And mut { Reference $2 }
| QuestionMark { Try }
| binary_op { BinaryOp $1 }
| Identifier { FieldAccess $1 }
| NumLiteral { ElementAccess $1 }
| Identifier tuple { MethodCall {
    func = $1;
    generic_args = [];
    args = $2;
} }
| goto_kw label { GoTo ($2, $1) }
| KwDefer label { Defer $2 }
| match { Match $1 }
| if { If $1 }
| KwFor label variable block { For {
    for_element = $3;
    for_block = $4;
    for_label = $2;
} }
| KwWhile label block { While ($2, $3) }

blockless_expr:
| Identifier { Variable $1 }
| literal { Literal $1 }
| unary_op expr { UnaryOp {
    unary_op = $1;
    unary_value = $2;
} }
| expr binary_op expr { BinaryOp {
    binary_op = $2;
    left = $1;
    right = $3;
} }
| expr Equal expr { Assign {
    left = $1;
    right = $3;
} }
| OpenBracket expr CloseBracket { Index $2 }
// separate func and method call to differentiate
// method calls and field function pointer calls
| expr tuple { FuncCall {
    func = $1;
    generic_args = [];
    args = $2;
} }
| expr Dot postfix_expr { PostFixExpr ($1, $3) }
| KwUndefer label { UnDefer $2 }

statements:
| { {statements = []; trailing_semicolon = true} }
| expr { {statements = [Expr $1]; trailing_semicolon = false} }
| item statements {
    let {statements; trailing} = $2 in
    let statements = (Item $1) :: statements in
    {statements; trailing_semicolon}
}
| expr SemiColon statements { 
    let {statements; trailing} = $3 in
    let statements = (Expr $1) :: statements in
    {statements; trailing_semicolon}
}

block:
| OpenBrace statements CloseBrace { $2 }

expr:
| blockless_expr { $1 }
| block { Block $1 }
| OpenParen expr CloseParen { $2 }

// if it's not a {} block, ends with a ;
terminating_expr:
| blockless_expr SemiColon { $1 }
| block { BlockExpr $1 }

variables:
| { [] }
| meta_variable Comma { [$1] }
| meta_variable Comma variables { $1 :: $3 }

func_arg:
| meta_variable { $1 }

func_args:
| variables { $1 }

func_decl_type:
| OpenParen func_args CloseParen type_annotation { {
    args = $2;
    return_type = $4;
} }

func_decl_signature:
| KwFn WhiteSpace Identifier func_decl_type { {
    name = $3;
    func_type = $4;
} }

func_decl:
| func_decl_signature SemiColon { {
    signature = $1;
    func_value = None;
} }
| func_decl_signature Equal terminating_expr { {
    signature = $1;
    func_value = Some $3;
} }

fields:
| variables { $1 }

struct_decl:
| KwStruct WhiteSpace Identifier OpenBrace fields CloseBrace { {
    name = $3;
    fields = $5;
} }

variant_data:
| { None }
| tuple_type { Some (TupleVariant $1) }
| fields { Some (StructVariant $1) }

variant:
| Identifier variant_data { {
    name = $1;
    data = $2;
} }

variants:
| { [] }
| variant Comma { [$1] }
| variant Comma variants { $1 :: $3 }

enum_decl:
| KwEnum WhiteSpace Identifier OpenBrace variants CloseBrace { {
    name = $3;
    variants = $5;
} }

union_decl:
| KwUnion WhiteSpace Identifier OpenBrace fields CloseBrace { {
    name = $3;
    fields = $5;
} }

module_or_impl:
| Identifier OpenBrace module_body CloseBrace { {
    name = $1;
    body = $3;
} }

impl:
| KwImpl WhiteSpace module_or_impl { Impl $3 }

mod:
| KwMod WhiteSpace module_or_impl { Mod $3 }

inner_item:
| use { $1 }
| let_ { $1 }
| func_decl { $1 }
| struct_decl { $1 }
| enum_decl { $1 }
| union_decl { $1 }
| impl { $1 }
| mod { $1 }

item:
| metadata inner_item { {
    metadata = $1;
    inner_item = $2;
} }

items:
| { [] }
| item items { $1 :: $2 }

module_body:
| items { {items = $1} }
;
