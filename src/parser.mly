%{ 
    open Ast
    open Token
%}

%token WhiteSpace

%start module_
%type <Ast.module_> module_

%%

module_:
| WhiteSpace { {name = "", items = []} }
;


