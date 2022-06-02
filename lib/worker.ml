open Core
open Async

exception Stop of string

let fetch_and_insert_restaurant restaurant_uri =
  let%bind restaurant_result =
    try_with (fun () ->
        let%bind _, body =
          Cohttp_async.Client.get
            (Uri.of_string
               (sprintf "https://guide.michelin.com%s" restaurant_uri))
        in
        let%bind body_str = Cohttp_async.Body.to_string body in
        let restaurant = Michelin.parse_restaurant body_str in
        return restaurant)
  in
  match restaurant_result with
  | Ok r ->
      let%bind _ = Postgres.add_restaurant r in
      return (Ok ())
  | Error exn -> return (Error exn)

let is_on_database restaurant_uri =
  let%bind result = Postgres.check_restaurant restaurant_uri in
  match Result.map result ~f:(fun l -> not (List.is_empty l)) with
  | Ok b -> return b
  | Error exn ->
      Caqti_error.show exn |> print_endline;
      failwith (Caqti_error.show exn)

let is_not_on_database restaurant_uri =
  let%bind on_database = is_on_database restaurant_uri in
  return (not on_database)

let get_and_save_restaurant restaurant_uri =
  print_endline "> Fetch Restaurant Started ";
  print_string restaurant_uri;
  print_endline "";

  let%bind result = fetch_and_insert_restaurant restaurant_uri in
  match result with
  | Ok _ ->
      print_endline "> Saved Restaurant ";
      print_string restaurant_uri;
      print_endline "";
      return (Ok restaurant_uri)
  | Error exn ->
      Exn.to_string exn |> print_endline;
      return (Error restaurant_uri)

let rec call_page_url num =
  let%bind response, body =
    Cohttp_async.Client.get
      (Uri.of_string
         (sprintf "https://guide.michelin.com/en/restaurants/page/%d" num))
  in
  if phys_equal response.status `Forbidden then (
    print_endline "> Get URLS Failed with Forbidden";
    let%bind _ = after (sec 100.0) in
    call_page_url num)
  else return (response, body)

let get_restaurant_urls_from_page page_num =
  let%bind response, body = call_page_url page_num in
  if phys_equal response.status `OK then
    let%bind body_str = Cohttp_async.Body.to_string body in
    let urls = Michelin.parse_page body_str in
    Deferred.List.filter urls ~f:is_not_on_database
  else if phys_equal response.status `Not_found then raise (Stop "end page")
  else failwith "Status nao esperado"

let rec get_all_urls_not_saved n acc =
  let open Deferred.Let_syntax in
  let%bind urls = try_with (fun _ -> get_restaurant_urls_from_page n) in
  match urls with
  | Ok urls ->
      let incremented_urls = List.append acc urls in
      print_endline "Page Num ";
      print_int n;
      print_endline "";
      print_endline "Urls Acc ";
      print_int (List.length incremented_urls);
      print_endline "";

      if List.equal String.equal incremented_urls acc then (
        print_endline "Stop Iter Pages";
        List.iter acc ~f:print_endline;
        return acc)
      else get_all_urls_not_saved (n + 1) incremented_urls
  | Error (Stop _) ->
      print_endline "Stop Iter Pages";
      List.iter acc ~f:print_endline;
      return acc
  | Error exn ->
      print_endline "Exception on Iter Pages";
      Exn.to_string exn |> print_endline;
      List.iter acc ~f:print_endline;
      return acc
