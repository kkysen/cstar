open Core
module LL = Llvm
module LLAnalysis = Llvm_analysis
open Lir
module Scope = Map.Make (String)

type scope = LL.llvalue Scope.t

type num_kind =
  | UnSigned
  | Signed
  | Float

let type_num_kind (t : type_) : num_kind option =
  match t with
  | IntType t ->
      Some
        (match t.unsigned with
        | true -> UnSigned
        | false -> Signed)
  | FloatType _ -> Some Float
  | PointerType _ -> Some UnSigned
  | _ -> None
;;

let float_type_bits (t : float_type) : int =
  match t with
  | F32 -> 32
  | F64 -> 64
;;

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

  let compile_const (lit : literal) (t : type_) : LL.llvalue =
    let t = compile_type t in
    match lit with
    | Int i -> LL.const_int t i
    | Float f -> LL.const_float t f
  in

  let rec compile_expr (expr : expr) ~(scope : scope) ~(irb : LL.llbuilder)
      : LL.llvalue
    =
    let {type_ = t; value} = expr in
    let value =
      match value with
      | Literal lit -> compile_const lit t
      | Var name -> Scope.find_exn scope name
      | UnaryOp (op, expr) ->
          let value = compile_expr expr ~scope ~irb in
          let t = LL.type_of value in
          let op =
            match op with
            | Negate -> LL.build_neg
            | Not -> LL.build_icmp LL.Icmp.Ne (LL.const_int t 0)
            | BitNot -> LL.build_not
            | AddressOf ->
                fun v n irb ->
                  let var = LL.build_alloca t n irb in
                  let store = LL.build_store v var irb in
                  ignore store;
                  var
            | Dereference -> LL.build_load
          in
          let value = op value "" irb in
          value
      | BinaryOp (lhs, op, rhs) ->
          let kind = type_num_kind expr.type_ in
          let lhs = compile_expr lhs ~scope ~irb in
          let rhs = compile_expr rhs ~scope ~irb in
          let op =
            match op with
            | Assign -> fun v p _n irb -> LL.build_store v p irb
            | Arithmetic op -> (
                let kind = Option.value_exn kind in
                match op with
                | Add -> LL.build_add
                | Subtract -> LL.build_sub
                | Multiply -> LL.build_mul
                | Divide -> (
                    match kind with
                    | UnSigned -> LL.build_udiv
                    | Signed -> LL.build_sdiv
                    | Float -> LL.build_fdiv)
                | Modulo -> (
                    match kind with
                    | UnSigned -> LL.build_urem
                    | Signed -> LL.build_srem
                    | Float -> LL.build_frem)
                | And | BitAnd -> LL.build_and
                | Or | BitOr -> LL.build_or
                | BitXor -> LL.build_xor
                | LeftShift -> LL.build_shl
                | RightShift -> (
                    match kind with
                    | UnSigned -> LL.build_lshr
                    | Signed -> LL.build_ashr
                    | Float -> failwith "float shift impossible"))
            | Comparison op -> (
                let kind = Option.value_exn kind in
                match kind with
                | UnSigned ->
                    let pred =
                      match op with
                      | Equal -> LL.Icmp.Eq
                      | NotEqual -> LL.Icmp.Ne
                      | LessThan -> LL.Icmp.Ult
                      | LessThanOrEqual -> LL.Icmp.Ule
                      | GreaterThan -> LL.Icmp.Ugt
                      | GreaterThanOrEqual -> LL.Icmp.Uge
                    in
                    LL.build_icmp pred
                | Signed ->
                    let pred =
                      match op with
                      | Equal -> LL.Icmp.Eq
                      | NotEqual -> LL.Icmp.Ne
                      | LessThan -> LL.Icmp.Slt
                      | LessThanOrEqual -> LL.Icmp.Sle
                      | GreaterThan -> LL.Icmp.Sgt
                      | GreaterThanOrEqual -> LL.Icmp.Sge
                    in
                    LL.build_icmp pred
                | Float ->
                    let pred =
                      match op with
                      | Equal -> LL.Fcmp.Oeq
                      | NotEqual -> LL.Fcmp.One
                      | LessThan -> LL.Fcmp.Olt
                      | LessThanOrEqual -> LL.Fcmp.Ole
                      | GreaterThan -> LL.Fcmp.Ogt
                      | GreaterThanOrEqual -> LL.Fcmp.Oge
                    in
                    LL.build_fcmp pred)
          in
          let value = op lhs rhs "" irb in
          value
      | Cast expr ->
          let value = compile_expr expr ~scope ~irb in
          let u = expr.type_ in
          let nop v _t _n _b = v in
          let op =
            match (u, t) with
            | (IntType u, IntType t) -> (
                match (u.unsigned, t.unsigned) with
                | (true, true) ->
                    if u.bits < t.bits
                    then LL.build_zext
                    else if u.bits > t.bits
                    then LL.build_trunc
                    else nop
                | (false, false) ->
                    if u.bits < t.bits
                    then LL.build_sext
                    else if u.bits > t.bits
                    then LL.build_trunc
                    else nop
                | (_, _) -> LL.build_bitcast)
            | (FloatType u, FloatType t) ->
                let ubits = float_type_bits u in
                let tbits = float_type_bits t in
                if ubits < tbits
                then LL.build_fpext
                else if ubits > tbits
                then LL.build_fptrunc
                else nop
            | (IntType u, FloatType _t) -> (
                match u.unsigned with
                | true -> LL.build_uitofp
                | false -> LL.build_sitofp)
            | (FloatType _u, IntType t) -> (
                match t.unsigned with
                | true -> LL.build_fptoui
                | false -> LL.build_fptosi)
            | (IntType _u, PointerType _v) -> LL.build_inttoptr
            | (PointerType _u, IntType _v) -> LL.build_ptrtoint
            | (_, _) -> LL.build_bitcast
          in
          let value = op value (compile_type t) "" irb in
          value
      | Call {callee; call_args = args} ->
          let callee = compile_expr callee ~scope ~irb in
          let args = args |> Array.map ~f:(compile_expr ~scope ~irb) in
          let value = LL.build_call callee args "" irb in
          value
      | If {condition; then_case; else_case} -> (
        let _condition = compile_expr condition ~scope ~irb in
        ignore then_case;
        ignore else_case;
        failwith "TODO: if"
      )
      | GoTo _expr -> (
        failwith "TODO goto"
      )
      | Block exprs ->
          exprs
          |> List.fold ~init:None ~f:(fun _ expr ->
                 Some (compile_expr expr ~scope ~irb))
          |> Option.value_exn
    in
    value
  in

  let compile_global (g : global) : unit =
    let {global_name = name; global_type = t; global_value = value} = g in
    let g = Scope.find_exn global_scope name in
    match value with
    | Some value ->
        let value = compile_const value t in
        LL.set_initializer value g
    | None ->
        LL.set_externally_initialized true g;
        ()
  in

  let compile_func_decl (decl : func_decl) (f : LL.llvalue) : unit =
    let {arg_names; func_value} = decl in
    let entry = LL.entry_block f in
    let irb = LL.builder_at_end ctx entry in
    let scope =
      Array.zip_exn arg_names (LL.params f)
      |> Array.fold ~init:global_scope ~f:(fun scope (name, param) ->
             LL.set_value_name (name ^ ".param") param;
             let t = LL.type_of param in
             let local = LL.build_alloca t name irb in
             let store = LL.build_store param local irb in
             ignore store;
             Scope.add_exn scope ~key:name ~data:local)
    in
    let ret_val = compile_expr func_value ~scope ~irb in
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