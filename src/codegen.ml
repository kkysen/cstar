open Core 
module LL = Llvm
module LLAnalysis = Llvm_analysis
module LLTarget = Llvm_target


let ctx = LL.global_context ()
let mod_ = LL.create_module ctx "TODO: replace me"
let target_triple = LLTarget.Target.default_triple ()
let i8 = LL.i8_type ctx 
let i32 = LL.i32_type ctx 
let i64 = LL.i64_type ctx 
let puts =
  let type_ = LL.function_type i32 [|LL.pointer_type i8|] in
  LL.declare_function "puts" type_ mod_ 

  let main =
    let type_ = LL.function_type i32 [||] in
    let func = LL.define_function "main" type_ mod_ in
    let entry = LL.entry_block func in
    let irb = LL.builder_at_end ctx entry in
    let hello_world_const = LL.const_stringz ctx "Hello, World!" in
    let hello_world_global = LL.define_global "" hello_world_const mod_ in
    let zero_i64 = LL.const_int i64 0 in
    let hello_world_local =
      LL.build_in_bounds_gep hello_world_global [|zero_i64; zero_i64|] "" irb
    in
    let (_ : LL.llvalue) = LL.build_call puts [|hello_world_local|] "" irb in
    let zero_i32 = LL.const_int i32 0 in
    let (_ : LL.llvalue) = LL.build_ret zero_i32 irb in
    func ;;