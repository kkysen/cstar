val value_or_thunk : 'a option -> default:(unit -> 'a) -> 'a

val list_from_fn : (unit -> 'a option) -> 'a list

