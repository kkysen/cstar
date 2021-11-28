module LL = Llvm
module LLAnalysis = Llvm_analysis
module LLTarget = Llvm_target

let compile ~(ctx : LL.llcontext) ~(mod_ : LL.llmodule) : unit = 
  let i8 = LL.i8_type ctx in
  let i32 = LL.i32_type ctx in
  let i64 = LL.i64_type ctx in
  let puts =
    let type_ = LL.function_type i32 [|LL.pointer_type i8|] in
    LL.declare_function "puts" type_ mod_
  in
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
    func
  in
  LLAnalysis.assert_valid_function main;
  ()
;;

let compile_file ~(src_path : string) ~(out_path : string) : unit = 
  LL.enable_pretty_stacktrace ();
  let ctx = LL.global_context () in
  let mod_ = LL.create_module ctx src_path in
  let target_triple = LLTarget.Target.default_triple () in
  LL.set_target_triple target_triple mod_;
  compile ~ctx ~mod_;
  LLAnalysis.assert_valid_module mod_;
  LL.print_module out_path mod_;
  ()
;;
