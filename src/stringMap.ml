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

let yojson_of_t (to_yojson : 'a -> Yojson.Safe.t) (this : 'a t) : Yojson.Safe.t =
  this.map
  |> S.to_seq
  |> Seq.map (fun (k, v) -> (k, to_yojson v))
  |> List.of_seq
  |> fun entries -> `Assoc entries
;;

let t_of_yojson (of_yojson : Yojson.Safe.t -> 'a) (json : Yojson.Safe.t) : 'a t =
  json
  |> Yojson.Safe.Util.to_assoc
  |> List.to_seq
  |> Seq.map (fun (k, v) -> (k, of_yojson v))
  |> S.of_seq
  |> fun map -> {map}
;;
