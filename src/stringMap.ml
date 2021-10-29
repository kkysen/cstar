module S = Map.Make (String)

let pp_map
    (pp : Format.formatter -> 'a -> unit)
    (fmt : Format.formatter)
    (this : 'a S.t)
    : unit
  =
  this
  |> S.to_seq
  |> Format.pp_print_seq
       (fun fmt (k, v) ->
         Format.fprintf fmt "%s: " k;
         pp fmt v)
       fmt
;;

type 'a t = {map : 'a S.t [@polyprinter pp_map]} [@@deriving show]
