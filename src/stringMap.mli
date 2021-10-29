module S : Map.S with type key = string

type 'a t = {map : 'a S.t} [@@deriving show]

(* val pp : Format.formatter -> 'a t -> unit

val show : 'a t -> string *)
