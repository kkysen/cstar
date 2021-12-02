module S : Map.S with type key = string

type 'a t = {map : 'a S.t} [@@deriving show]

val yojson_of_t : ('a -> Yojson.Safe.t) -> 'a t -> Yojson.Safe.t
  
val t_of_yojson : (Yojson.Safe.t -> 'a) -> Yojson.Safe.t -> 'a t

(* val pp : Format.formatter -> 'a t -> unit

val show : 'a t -> string *)
