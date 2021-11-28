open Core

type t =
  | Src
  (* | Ast *)
  | Ir
  | Bc
  | Asm
  | Obj
  | Exe
[@@deriving show, eq, ord, enum]

let of_enum_exn (i : int) : t = i |> of_enum |> Option.value_exn

let all : t list = [Src; (* Ast; *) Ir; Bc; Asm; Obj; Exe]

let to_string (this : t) : string =
  match this with
  | Src -> "src"
  (* | Ast -> "ast" *)
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

let extension (this : t) : string =
  match this with
  | Src -> ".cstar"
  (* | Ast -> ".ast.json" *)
  | Ir -> ".ll"
  | Bc -> ".bc"
  | Asm -> ".s"
  | Obj -> ".o"
  | Exe -> ""
;;

let detect_by_extension (path : string) : t option =
  let ext =
    path
    |> Filename.split_extension
    |> snd
    |> Option.map ~f:(fun ext -> "." ^ ext)
    |> Option.value ~default:""
  in
  all |> List.find ~f:(fun it -> String.equal ext (extension it))
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
  (* | Ast -> false *)
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
