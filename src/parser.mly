%{ 
    open Ast
%}

%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA PLUS MINUS TIMES DIVIDE ASSIGN
%token NOT EQ NEQ LT LEQ GT GEQ AND OR
%token RETURN IF ELSE FOR WHILE INT BOOL FLOAT VOID
%token <int> LITERAL
%token <bool> BLIT
%token <string> ID FLIT
%token EOF FN

%start mod_
%type <Ast.mod_> mod_

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left TIMES DIVIDE
%right NOT

%%

defns: 
    /* nothing */   { [] }
    | defns defn    { defns @ [defn]}

defn:
      func_def      {$1}
    | var_def SEMI  {$1}
    | mod           {$1}

func_def:
    FN ID LBRACE body RBRACE { }
var_def:
    LET ID typ_ann_opt EQ expr { }
mod: 
    MOD LBRACE defns RBRACE { Mod $1 }