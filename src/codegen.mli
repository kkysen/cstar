module LL = Llvm
open Lir

val compile : lir:lir -> ctx:LL.llcontext -> mod_:LL.llmodule -> unit
