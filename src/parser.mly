%{ 
    open Ast
    open Token
%}

%start module_
%type <Ast.module_> module_

%%

module_:
//     let_  {Let()}
//   | impl  {Impl()}

;


