open Core
open Async
open Cohttp_async

let bot_token = Sys.getenv_exn "BOT_TOKEN"
let expected_resource = Printf.sprintf "/%s" bot_token

let start_server port () =
  Cohttp_async.Server.create ~on_handler_error:`Raise
    (Async.Tcp.Where_to_listen.of_port port) (fun ~body _ req ->
      match req |> Cohttp.Request.meth with
      | `POST ->
          let resource = Request.resource req in
          print_endline resource;
          if phys_equal resource expected_resource then (
            Body.to_string body >>= fun body ->
            print_endline body;
            print_endline "Update received";
            Server.respond `OK)
          else Server.respond `Forbidden
      | _ -> Server.respond `Method_not_allowed)
  >>= fun _ -> Deferred.never ()

let () =
  let module Command = Async_command in
  Command.async_spec ~summary:"Simple http server that outputs body of POST's"
    Command.Spec.(
      empty
      +> flag "-p"
           (optional_with_default 8080 int)
           ~doc:"int Source port to listen on")
    start_server
  |> Command_unix.run