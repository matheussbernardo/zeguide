open Core
open Async
open Travelguide

(* open Cohttp *)
module Client = Cohttp_async.Client
module Body = Cohttp_async.Body

let () =
  don't_wait_for
    ( Postgres.migrate () >>= fun _ ->
      Worker.iter_pages 1 >>= fun str ->
      print_endline str;
      exit 0 );
  never_returns (Scheduler.go ())
