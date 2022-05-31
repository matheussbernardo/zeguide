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
        print_endline "> Fetch Restaurant HTTP";
        let restaurant = Michelin.parse_restaurant body_str in
        print_endline "> Fetch Restaurant Parse";
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
  let%bind on_database = is_on_database restaurant_uri in
  match on_database with
  | false ->
      let fetch' restaurant_uri =
        print_endline "> Fetch Restaurant Started";
        let%bind result = fetch_and_insert_restaurant restaurant_uri in
        match result with
        | Ok _ -> return (Ok restaurant_uri)
        | Error exn ->
            Exn.to_string exn |> print_endline;
            return (Error restaurant_uri)
      in
      fetch' restaurant_uri
  | true -> return (Ok restaurant_uri)

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
  else failwith "DEU MERDA"

let rec get_all_urls_not_saved n acc =
  let open Deferred.Let_syntax in
  let%bind urls = try_with (fun _ -> get_restaurant_urls_from_page n) in
  match urls with
  | Ok urls ->
      let incremented_urls = List.append acc urls in
      print_endline "-------";
      List.iter incremented_urls ~f:print_endline;
      print_endline "-------";
      get_all_urls_not_saved (n + 1) incremented_urls
  | Error (Stop _) -> return acc
  | Error _ -> failwith "DEU MERDA"
