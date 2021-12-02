open Core

type t =
  | Src
  | Tokens
  | Ast
  | DesugaredAst
  | TypedAst
  | Ir
  | Bc
  | Asm
  | Obj
  | Exe
[@@deriving show, eq, ord, enum]

let of_enum_exn (i : int) : t = i |> of_enum |> Option.value_exn

let all : t list =
  [Src; Tokens; Ast; DesugaredAst; TypedAst; Ir; Bc; Asm; Obj; Exe]
;;

let to_string (this : t) : string =
  match this with
  | Src -> "src"
  | Tokens -> "tokens"
  | Ast -> "ast"
  | DesugaredAst -> "desugared-ast"
  | TypedAst -> "typed-ast"
  | Ir -> "ir"
  | Bc -> "bc"
  | Asm -> "asm"
  | Obj -> "obj"
  | Exe -> "exe"
;;

let of_string (s : string) : t =
  all
  |> List.find ~f:(fun it -> String.equal s (to_string it))
  |> Option.value_exn ?message:(Some "invalid emit type")
;;

let base_extension = "cstar"

let extensions (this : t) : string list =
  match this with
  | Src -> [base_extension]
  | Tokens -> [base_extension; "tokens"; "json"]
  | Ast -> [base_extension; "raw"; "ast"; "json"]
  | DesugaredAst -> [base_extension; "desugared"; "ast"; "json"]
  | TypedAst -> [base_extension; "typed"; "ast"; "json"]
  | Ir -> [base_extension; "ll"]
  | Bc -> [base_extension; "bc"]
  | Asm -> [base_extension; "s"]
  | Obj -> [base_extension; "o"]
  | Exe -> [] (* or like Dune: [base_extension; "exe"] *)
;;

let extension (this : t) : string =
  this |> extensions |> (fun a -> "" :: a) |> String.concat ?sep:(Some ".")
;;

let detect_by_extension (path : string) : t option =
  all |> List.find ~f:(fun t -> String.is_suffix ~suffix:(extension t) path)
;;

(* TODO For example, llvm bitcode starts with `BC\OxCO\OxD\OxE` (`BCOxC0DE`). *)
let detect_by_magic (_path : string) : t option = None

let detect ~(path : string) : t option =
  [detect_by_extension; detect_by_magic]
  |> List.fold ~init:(Ok ()) ~f:(fun acc f ->
         match acc with
         | Ok () -> (
             match f path with
             | Some emit -> Error emit
             | None -> Ok ())
         | Error emit -> Error emit)
  |> Result.error
;;

let detect_exn ~(path : string) : t =
  detect ~path |> Option.value_exn ?message:(Some "couldn't detect file type")
;;

let is_llvm (this : t) : bool =
  match this with
  | Src -> false
  | Tokens -> false
  | Ast -> false
  | DesugaredAst -> false
  | TypedAst -> false
  | Ir -> true
  | Bc -> true
  | Asm -> true
  | Obj -> true
  | Exe -> true
;;

let arg : t Command.Arg_type.t =
  all
  |> List.map ~f:(fun it -> (to_string it, it))
  |> String.Map.of_alist_exn
  |> Command.Arg_type.of_map
;;
