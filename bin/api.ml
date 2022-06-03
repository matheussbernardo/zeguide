open Core
open Async
open Cohttp_async
open Travelguide

let parse_request lat lon =
  let lat = Float.of_string lat in
  let lon = Float.of_string lon in
  (lat, lon, 10000.0)

let start_server port () =
  Cohttp_async.Server.create ~on_handler_error:`Raise
    (Async.Tcp.Where_to_listen.of_port port) (fun ~body:_ _ req ->
      let uri = Request.uri req in
      let resource_path = Uri.path uri in
      match req |> Cohttp.Request.meth with
      | `GET ->
          if String.equal resource_path "/near" then
            let latitude = Uri.get_query_param uri "lat" in
            let longitude = Uri.get_query_param uri "lon" in
            if Option.is_some latitude && Option.is_some longitude then
              let lat, lon, within =
                parse_request
                  (Option.value_exn latitude)
                  (Option.value_exn longitude)
              in
              let%bind restaurants = Api.get_restaurants_near lat lon within in
              let response =
                Result.ok_or_failwith restaurants
                |> List.map ~f:(fun r -> Api.yojson_of_restaurant r)
              in
              let json = `List response in
              Server.respond_string ~status:`OK (Yojson.Safe.to_string json)
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