open Core
module LL = Llvm
module LLAnalysis = Llvm_analysis
open Lir
module Scope = Map.Make (String)

type scope = LL.llvalue Scope.t

let compile ~(lir : lir) ~(ctx : LL.llcontext) ~(mod_ : LL.llmodule) : unit =
  let rec compile_type (t : type_) : LL.lltype =
    match t with
    | UnitType -> LL.void_type ctx
    | IntType t -> LL.integer_type ctx t.bits
    | FloatType t -> (
        match t with
        | F32 -> LL.float_type ctx
        | F64 -> LL.double_type ctx)
    | PointerType t -> t |> compile_type |> LL.pointer_type
    | ArrayType (t, len) -> (t |> compile_type |> LL.array_type) len
    | TupleType ts -> ts |> Array.map ~f:compile_type |> LL.struct_type ctx
    | FuncType {func_args; func_return_type} ->
        let args = func_args |> Array.map ~f:compile_type in
        let return_type = func_return_type |> compile_type in
        LL.function_type return_type args
  in

  let declare_global (g : global) : LL.llvalue =
    let {global_name = name; global_type = t; global_value = _} = g in
    let t = compile_type t in
    let g = LL.declare_global t name mod_ in
    g
  in

  let declare_func (f : func) : LL.llvalue =
    let {func_name = name; func_type = t; func_decl = decl} = f in
    let t = compile_type (FuncType t) in
    let f =
      (match decl with
      | Some _ -> LL.define_function
      | None -> LL.declare_function)
        name
        t
        mod_
    in
    f
  in

  let create_scope (values : LL.llvalue list) : scope =
    values
    |> Sequence.of_list
    |> Sequence.map ~f:(fun v -> (LL.value_name v, v))
    |> Scope.of_sequence_exn
  in

  let {globals; functions; _} = lir in

  let global_scope =
    create_scope
      (let globals = globals |> List.map ~f:declare_global in
       let functions = functions |> List.map ~f:declare_func in
       globals @ functions)
  in

  let compile_expr (expr : expr) ~(scope : scope) : LL.llvalue =
    ignore expr;
    ignore scope;
    failwith "TODO"
  in

  let compile_global (g : global) : unit =
    let {global_name = name; global_type = t; global_value = value} = g in
    let g = Scope.find_exn global_scope name in
    match value with
    | Some value ->
        let value =
          compile_expr {type_ = t; value = Literal value} ~scope:Scope.empty
        in
        LL.set_initializer value g
    | None ->
        LL.set_externally_initialized true g;
        ()
  in

  let compile_func_decl (decl : func_decl) (f : LL.llvalue) : unit =
    let {arg_names; func_value} = decl in
    let scope =
      Array.zip_exn arg_names (LL.params f)
      |> Array.fold ~init:global_scope ~f:(fun scope (name, param) ->
             LL.set_value_name name param;
             Scope.add_exn scope ~key:name ~data:param)
    in
    let ret_val = compile_expr func_value ~scope in
    ignore ret_val;
    failwith "TODO"
  in

  let compile_func (f : func) : unit =
    let {func_name = name; func_type = _; func_decl = decl} = f in
    let f = Scope.find_exn global_scope name in
    (match decl with
    | Some decl -> compile_func_decl decl f
    | None -> ());
    LLAnalysis.assert_valid_function f;
    ()
  in

  globals |> List.iter ~f:compile_global;
  functions |> List.iter ~f:compile_func;

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