(* Ensure that operator and record sections result in semi-sane code. *)
let main = ( (+), (2*), (/2), (.foo) )

external val ignore : 'a -> () = "nil"
let () = ignore main
