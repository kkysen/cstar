module type Stage = sig
  type input

  type output

  val compile : input -> output

  val compile_file : input_path:string -> output_path:string -> unit
end

module Lex : Stage
module Parse : Stage
module Desugar : Stage
module TypeCheck : Stage
module CodeGen : Stage

type src = {
    path : string
  ; code : string
} [@@deriving show, yojson]

type token_src = {
    src : src
  ; tokens : Token.token list
}
[@@deriving show, yojson]

type desugared_ast = {path : string} [@@deriving show, yojson]

type typed_ast = {path : string} [@@deriving show, yojson]
