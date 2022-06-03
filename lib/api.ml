open Core
open Async

(* // raio - 100m, 500m, 1km, 2km, 5km
   // limitar 10 primeiros
   // filtros, estrelas michelin, bib gourmand, *)
type restaurant = {
  name : string;
  latitude : float;
  longitude : float;
  distance : float;
}
[@@deriving yojson, sexp, show, compare]

let from_crawler json_str distance =
  let open Yojson.Basic.Util in
  let json = Yojson.Basic.from_string json_str in
  let name = json |> member "name" |> to_string in
  let latitude = json |> member "latitude" |> to_float in
  let longitude = json |> member "longitude" |> to_float in
  { name; latitude; longitude; distance }

let get_restaurants_near lat lon within =
  let open Deferred.Let_syntax in
  let%bind result = Postgres.get_restaurants_within lat lon within in
  return
    (Result.map result ~f:(fun restaurants ->
         List.map restaurants ~f:(fun (_, content, distance) ->
             from_crawler content distance)))
