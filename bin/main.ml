open Core
open Async
open Travelguide

(* open Cohttp *)
module Client = Cohttp_async.Client
module Body = Cohttp_async.Body

let () =
  don't_wait_for
    ( Postgres.migrate () >>= fun _ ->
      Worker.iter_pages 1 [] >>= fun str ->
      let errors = List.filter str ~f:Result.is_error in
      List.iter errors ~f:(fun r ->
          Result.iter_error r ~f:(fun e -> print_endline e));
      exit 0 );
  never_returns (Scheduler.go ())
