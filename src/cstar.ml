print_endline "Hello, world!"

let list_from_fn (f : unit -> 'a option) : 'a list =
  let rec next list =
    match f () with
    | None -> list
    | Some e -> next (e :: list)
  in
  next []
;;

let read_tokens (lexbuf : Lexing.lexbuf) : Token.token list =
  list_from_fn (fun () ->
      match Lexer.token lexbuf with
      | Token.EOF -> None
      | token -> Some token)
;;

let () =
  let lexbuf = Lexing.from_string "fn main() {}" in
  let tokens = read_tokens lexbuf in
  tokens |> List.map Token.show_token |> List.iter print_endline
;;
