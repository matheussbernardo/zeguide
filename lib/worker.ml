open Core
open Async

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

let get_and_save_restaurant restaurant_uri =
  let open Deferred.Let_syntax in
  let%bind result = Postgres.check_restaurant restaurant_uri in
  let not_on_database = Result.map result ~f:(fun l -> List.is_empty l) in
  match not_on_database with
  | Ok true ->
      let rec fetch' restaurant_uri =
        print_endline "> Fetch Restaurant Started";
        let%bind result = fetch_and_insert_restaurant restaurant_uri in
        match result with
        | Ok _ -> return ()
        | Error _ ->
            let%bind _ = after (sec 60.0) in
            let%bind _ = fetch' restaurant_uri in
            return ()
      in
      fetch' restaurant_uri
  | Ok false -> return ()
  | Error _ -> return ()

let get_restaurant_urls page_num =
  let open Deferred.Let_syntax in
  let%bind result =
    try_with (fun () ->
        let%bind response, body =
          Cohttp_async.Client.get
            (Uri.of_string
               (sprintf "https://guide.michelin.com/en/restaurants/page/%d"
                  page_num))
        in
        print_endline (Cohttp.Code.string_of_status response.status);
        if phys_equal response.status `Forbidden then (
          print_endline "> Get URLS Failed with Forbidden";
          failwith "Forbidden")
        else
          let%bind body_str = Cohttp_async.Body.to_string body in
          return body_str)
  in
  let urls = Result.map result ~f:Michelin.parse_page in
  return urls

let rec iter_pages n =
  let open Deferred.Let_syntax in
  print_string "Start iter_pages ITER <";
  print_int n;
  print_endline ">\n------------";
  let%bind restaurants_urls = get_restaurant_urls n in
  match restaurants_urls with
  | Ok [] -> return "End Page"
  | Ok urls ->
      List.iter urls ~f:(fun url -> print_endline url);
      let%bind _ =
        Deferred.List.iter ~how:`Parallel urls ~f:get_and_save_restaurant
      in
      iter_pages (n + 1)
  | Error e ->
      Exn.to_string e |> print_endline;
      let%bind _ = after (sec 60.0) in
      iter_pages n
