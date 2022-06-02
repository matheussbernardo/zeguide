open Core
open Async
(* // raio - 100m, 500m, 1km, 2km, 5km
   // limitar 10 primeiros
   // filtros, estrelas michelin, bib gourmand, *)

let get_restaurants_near lat lon within =
  let open Deferred.Let_syntax in
  let%bind result = Postgres.get_restaurants_within lat lon within in
  return (Result.map result ~f:(fun restaurants -> restaurants))
