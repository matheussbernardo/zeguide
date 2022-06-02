open Core
open Async
open Cohttp_async

let start_server port () =
  Cohttp_async.Server.create ~on_handler_error:`Raise
    (Async.Tcp.Where_to_listen.of_port port) (fun ~body:_ _ req ->
      let uri = Request.uri req in
      let resource_path = Uri.path uri in
      match req |> Cohttp.Request.meth with
      | `GET ->
          if String.equal resource_path "/near" then
            let latitude = Uri.get_query_param uri "lat" in
            let longitutde = Uri.get_query_param uri "lon" in
            if Option.is_some latitude && Option.is_some longitutde then (
              print_endline "Update received";
              Server.respond `OK)
            else Server.respond `Bad_request
          else Server.respond `Not_found
      | _ -> Server.respond `Method_not_allowed)
  >>= fun _ -> Deferred.never ()

let () =
  let module Command = Async_command in
  Command.async_spec
    ~summary:
      "Simple http server that receives location and returns near restaurants"
    Command.Spec.(
      empty
      +> flag "-p"
           (optional_with_default 8080 int)
           ~doc:"int Source port to listen on")
    start_server
  |> Command_unix.run