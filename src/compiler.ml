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
}
[@@deriving show, yojson]

type token_src = {
    src : src
  ; tokens : Token.token list
}
[@@deriving show, yojson]

type desugared_ast = {path : string} [@@deriving show, yojson]

type typed_ast = {path : string} [@@deriving show, yojson]

module Lex = MakeStage (struct
  type input = src

  type output = token_src

  let from_file ~(path : string) () = {path; code = In_channel.read_all path}

  let to_file = json_serializer yojson_of_token_src

  let compile (src : src) : token_src =
    let lexbuf = Lexing.from_string src.code in
    let tokens =
      Util.list_from_fn (fun () ->
          match Lexer.token lexbuf with
          | Token.EOF -> None
          | token -> Some token)
    in
    {src; tokens}
  ;;
end)

module Parse = MakeStage (struct
  type input = token_src

  type output = Ast.ast

  let from_file = json_deserializer token_src_of_yojson

  let to_file = json_serializer Ast.yojson_of_ast

  let translate_token (token : Token.token) : Parser.token =
    match token with
    | Token.EOF -> Parser.EOF
    | Token.WhiteSpace s -> Parser.WhiteSpace s
    | Token.Comment comment -> (
        match comment with
        | Token.Structural -> Parser.StructuralComment
        | Token.Line s -> Parser.LineComment s
        | Token.Block s -> Parser.BlockComment s)
    | Token.Identifier s -> Parser.Identifier s
    | Token.Literal literal -> (
        match literal with
        | Token.Number n -> Parser.NumberLiteral n
        | Token.Char c -> Parser.CharLiteral c
        | Token.String s -> Parser.StringLiteral s)
    | Token.Keyword kw -> (
        match kw with
        | Token.KwMod -> Parser.KwMod
        | Token.KwUse -> Parser.KwUse
        | Token.KwLet -> Parser.KwLet
        | Token.KwMut -> Parser.KwMut
        | Token.KwPub -> Parser.KwPub
        | Token.KwTry -> Parser.KwTry
        | Token.KwConst -> Parser.KwConst
        | Token.KwImpl -> Parser.KwImpl
        | Token.KwFn -> Parser.KwFn
        | Token.KwStruct -> Parser.KwStruct
        | Token.KwEnum -> Parser.KwEnum
        | Token.KwUnion -> Parser.KwUnion
        | Token.KwReturn -> Parser.KwReturn
        | Token.KwBreak -> Parser.KwBreak
        | Token.KwContinue -> Parser.KwContinue
        | Token.KwFor -> Parser.KwFor
        | Token.KwWhile -> Parser.KwWhile
        | Token.KwIf -> Parser.KwIf
        | Token.KwElse -> Parser.KwElse
        | Token.KwMatch -> Parser.KwMatch
        | Token.KwDefer -> Parser.KwDefer
        | Token.KwUndefer -> Parser.KwUndefer
        | Token.KwIn -> Parser.KwIn
        | Token.KwTrait -> Parser.KwTrait)
    | Token.SemiColon -> Parser.SemiColon
    | Token.Colon -> Parser.Colon
    | Token.Comma -> Parser.Comma
    | Token.Dot -> Parser.Dot
    | Token.DotDot -> Parser.DotDot
    | Token.OpenParen -> Parser.OpenParen
    | Token.CloseParen -> Parser.CloseParen
    | Token.OpenBrace -> Parser.OpenBrace
    | Token.CloseBrace -> Parser.CloseBrace
    | Token.OpenBracket -> Parser.OpenBracket
    | Token.CloseBracket -> Parser.CloseBracket
    | Token.At -> Parser.At
    | Token.QuestionMark -> Parser.QuestionMark
    | Token.ExclamationPoint -> Parser.ExclamationPoint
    | Token.Equal -> Parser.Equal
    | Token.EqualEqual -> Parser.EqualEqual
    | Token.NotEqual -> Parser.NotEqual
    | Token.LessThan -> Parser.LessThan
    | Token.GreaterThan -> Parser.GreaterThan
    | Token.LessThanOrEqual -> Parser.LessThanOrEqual
    | Token.GreaterThanOrEqual -> Parser.GreaterThanOrEqual
    | Token.LeftShift -> Parser.LeftShift
    | Token.RightShift -> Parser.RightShift
    | Token.Arrow -> Parser.Arrow
    | Token.Plus -> Parser.Plus
    | Token.Minus -> Parser.Minus
    | Token.Times -> Parser.Times
    | Token.Divide -> Parser.Divide
    | Token.And -> Parser.And
    | Token.Or -> Parser.Or
    | Token.AndAnd -> Parser.AndAnd
    | Token.OrOr -> Parser.OrOr
    | Token.Caret -> Parser.Caret
    | Token.Percent -> Parser.Percent
    | Token.Tilde -> Parser.Tilde
    | Token.Pound -> Parser.Pound
    | Token.DollarSign -> Parser.DollarSign
  ;;

  let parse_token (lexbuf : Lexing.lexbuf) : Parser.token =
    lexbuf |> Lexer.token |> translate_token
  ;;

  let compile (token_src : token_src) : Ast.ast =
    let {src; tokens} = token_src in
    let {path; code} = src in
    let lexbuf = Lexing.from_string code in
    let body = Parser.module_body parse_token lexbuf in
    let name = Filename.basename path in
    let module_ = {Ast.module_name = name; Ast.module_body = body} in
    let ast = {Ast.path; Ast.module_} in
    ignore tokens;
    ast
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

module Lower = MakeStage (struct
  type input = typed_ast

  type output = Lir.lir

  let from_file = json_deserializer typed_ast_of_yojson

  let to_file = json_serializer Lir.yojson_of_lir

  let compile (ast : typed_ast) : Lir.lir =
    Lir.(
      let u64 = IntType {bits = 64; unsigned = true} in
      let i64 = IntType {bits = 64; unsigned = false} in
      {path = ast.path; globals = []; functions = [
      {
        func_name = "gcd";
        func_type = {
          func_args = [|i64; i64|];
          func_return_type = i64;
        };
        func_decl = Some {
          arg_names = [|"a"; "b"|];
          func_value = {
            type_ = i64;
            value = Literal (Int 0);
          };
        };
      };
      {
        func_name = "gdb'";
        func_type = {
          func_args = [|u64; u64|];
          func_return_type = u64;
        };
        func_decl = Some {
          arg_names = [|"a"; "b"|];
          func_value = {
            type_ = u64;
            value = Literal (Int 0);
          };
        };
      }
    ]})
  ;;
end)

module CodeGen = MakeStage (struct
  type input = Lir.lir

  type output = LL.llcontext * LL.llmodule

  let from_file = json_deserializer Lir.lir_of_yojson

  let to_file ~(path : string) ((ctx, mod_) : LL.llcontext * LL.llmodule) : unit
    =
    LLAnalysis.assert_valid_module mod_;
    LL.print_module path mod_;
    LL.dispose_module mod_;
    LL.dispose_context ctx;
    ()
  ;;

  let compile (lir : Lir.lir) : LL.llcontext * LL.llmodule =
    LL.enable_pretty_stacktrace ();
    let ctx = LL.create_context () in
    let mod_ = LL.create_module ctx lir.path in
    let target_triple = LLTarget.Target.default_triple () in
    LL.set_target_triple target_triple mod_;
    Codegen.compile ~lir ~ctx ~mod_;
    (ctx, mod_)
  ;;
end)
