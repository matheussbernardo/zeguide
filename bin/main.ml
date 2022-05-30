open Core
open Async
open Travelguide

(* open Cohttp *)
module Client = Cohttp_async.Client
module Body = Cohttp_async.Body

let () =
  don't_wait_for
    ( Worker.iter_pages 500 >>= fun str ->
      print_endline str;
      exit 0 );
  never_returns (Scheduler.go ())
