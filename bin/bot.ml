open Core
open Async
open Cohttp_async

let bot_token = Sys.getenv_exn "BOT_TOKEN"
let expected_resource = Printf.sprintf "/%s" bot_token

let start_server port () =
  Cohttp_async.Server.create ~on_handler_error:`Raise
    (Async.Tcp.Where_to_listen.of_port port) (fun ~body _ req ->
      let uri = Request.uri req in
      let resource_path = Uri.path uri in
      match req |> Cohttp.Request.meth with
      | `POST ->
          if String.equal resource_path expected_resource then (
            Body.to_string body >>= fun body ->
            print_endline body;
            let json = Yojson.Basic.from_string body in
            let open Yojson.Basic.Util in
            let latitude =
              json |> member "message" |> member "location" |> member "latitude"
              |> to_string
            in
            let longitude =
              json |> member "message" |> member "location"
              |> member "longitude" |> to_string
            in
            let%bind response, _body =
              Cohttp_async.Client.get
                (Uri.add_query_params
                   (Uri.of_string "localhost:8082/near")
                   [ ("lat", [ latitude ]); ("lon", [ longitude ]) ])
            in
            print_int (Cohttp.Code.code_of_status response.status);
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