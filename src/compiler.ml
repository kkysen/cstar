open Core
module LL = Llvm
module LLAnalysis = Llvm_analysis
module LLTarget = Llvm_target

module type RawStage = sig
  type input

  type output

  val from_file : path:string -> unit -> input

  val to_file : path:string -> output -> unit

  val compile : input -> output
end

module type Stage = sig
  type input

  type output

  val compile : input -> output

  val compile_file : input_path:string -> output_path:string -> unit
end

module MakeStage : functor (RawStage : RawStage) -> Stage =
functor
  (RawStage : RawStage)
  ->
  struct
    type input = RawStage.input

    type output = RawStage.output

    let from_file = RawStage.from_file

    let to_file = RawStage.to_file

    let compile = RawStage.compile

    let compile_file ~(input_path : string) ~(output_path : string) : unit =
      () |> from_file ~path:input_path |> compile |> to_file ~path:output_path
    ;;
  end

let json_deserializer (deserializer : Yojson.Safe.t -> 'a)
    : path:string -> unit -> 'a
  =
 fun ~path () -> Yojson.Safe.from_file ~fname:path path |> deserializer
;;

let json_serializer (serializer : 'a -> Yojson.Safe.t)
    : path:string -> 'a -> unit
  =
 fun ~path a -> a |> serializer |> Yojson.Safe.to_file path
;;

type src = {
    path : string
  ; code : string
} [@@deriving show, yojson]

type desugared_ast = {path : string} [@@deriving show, yojson]

type typed_ast = {path : string} [@@deriving show, yojson]

module Lex = MakeStage (struct
  type input = src

  type output = Token.tokens

  let from_file ~(path : string) () = {path; code = In_channel.read_all path}

  let to_file = json_serializer Token.yojson_of_tokens

  let compile (src : src) : Token.tokens =
    let {path; code} = src in
    let lexbuf = Lexing.from_string code in
    let tokens = Util.list_from_fn (fun () -> 
      match Lexer.token lexbuf with
      | Token.EOF -> None
      | token -> Some token
    ) in
    {path; tokens}
  ;;
end)

module Parse = MakeStage (struct
  type input = Token.tokens

  type output = Ast.ast

  let from_file = json_deserializer Token.tokens_of_yojson

  let to_file = json_serializer Ast.yojson_of_ast

  let compile (tokens : Token.tokens) : Ast.ast =
    let {path; Token.tokens} = tokens in
    ignore tokens;
    {path; module_ = {name = "todo"; items = []}}
  ;;
end)

module Desugar = MakeStage (struct
  type input = Ast.ast

  type output = desugared_ast

  let from_file = json_deserializer Ast.ast_of_yojson

  let to_file = json_serializer yojson_of_desugared_ast

  let compile (ast : Ast.ast) : desugared_ast =
    let {path; Ast.module_} = ast in
    ignore module_;
    {path}
  ;;
end)

module TypeCheck = MakeStage (struct
  type input = desugared_ast

  type output = typed_ast

  let from_file = json_deserializer desugared_ast_of_yojson

  let to_file = json_serializer yojson_of_typed_ast

  let compile (ast : desugared_ast) : typed_ast = {path = ast.path}
end)

let compile ~(ast : typed_ast) ~(ctx : LL.llcontext) ~(mod_ : LL.llmodule) : unit =
  ignore ast;
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

module CodeGen = MakeStage (struct
  type input = typed_ast

  type output = LL.llmodule

  let from_file = json_deserializer typed_ast_of_yojson

  let to_file ~(path : string) (mod_ : LL.llmodule) : unit =
    LLAnalysis.assert_valid_module mod_;
    LL.print_module path mod_
  ;;

  let compile (ast : typed_ast) : LL.llmodule =
    LL.enable_pretty_stacktrace ();
    let ctx = LL.global_context () in
    let mod_ = LL.create_module ctx ast.path in
    let target_triple = LLTarget.Target.default_triple () in
    LL.set_target_triple target_triple mod_;
    compile ~ast ~ctx ~mod_;
    mod_
  ;;
end)
