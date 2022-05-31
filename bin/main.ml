open Core
open Async
open Travelguide

(* open Cohttp *)
module Client = Cohttp_async.Client
module Body = Cohttp_async.Body

let () =
  don't_wait_for
    ( Worker.get_all_urls_not_saved 1 [] >>= fun urls ->
      let%bind _restaurants =
        Deferred.List.map urls ~f:Worker.get_and_save_restaurant
      in
      exit 0 );
  never_returns (Scheduler.go ())
