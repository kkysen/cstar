%{ 
    open Ast
%}

%token EOF
%token <string> WhiteSpace
%token StructuralComment
%token <string> LineComment
%token <string> BlockComment
%token <Token.literal> Literal
%token <string> Identifier
%token KwUse
%token KwLet
%token KwMut
%token KwPub
%token KwIn
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
%token KwTrait
%token SemiColon
%token Colon
%token Comma
%token Dot
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
%token LessThan
%token GreaterThan
%token Plus
%token Minus
%token Times
%token Divide
%token And
%token Or
%token Caret
%token Percent
%token Tilde
%token Pound
%token DollarSign

%start module_body
%type <Ast.module_body> module_body



%%

// defns: 
//     /* nothing */   { [] }
//     | defns defn    { defns @ [defn]}

// defn:
//       func_def      {$1}
//     | var_def SEMI  {$1}
//     | mod           {$1}

// func_def:
//     FN ID LBRACE body RBRACE { }
// var_def:
//     LET ID typ_ann_opt EQ expr { }
// mod: 
//     MOD LBRACE defns RBRACE { Mod $1 }


module_body:
| WhiteSpace { {items = []} }
;
