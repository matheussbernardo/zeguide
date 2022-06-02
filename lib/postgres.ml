open Michelin

let db_user = Sys.getenv "DB_USER"
let db_pass = Sys.getenv "DB_PASSWORD"
let db_name = Sys.getenv "DB_NAME"

let connection_url =
  Printf.sprintf "postgresql://%s:%s@localhost:5432/%s" db_user db_pass db_name

let pool =
  match
    Caqti_async.connect_pool ~max_size:10 (Uri.of_string connection_url)
  with
  | Ok pool -> pool
  | Error err -> failwith (Caqti_error.show err)

let migrate_query =
  let open Caqti_request.Infix in
  let open Caqti_type in
  (unit ->. unit)
  @@ {| CREATE TABLE Restaurant (
          id text NOT NULL PRIMARY KEY,
          content jsonb
       )
    |}

let migrate () =
  let migrate' (module C : Caqti_async.CONNECTION) = C.exec migrate_query () in
  Caqti_async.Pool.use migrate' pool

let add_restaurant_query =
  let open Caqti_request.Infix in
  let open Caqti_type in
  (tup2 string string ->. unit)
  @@ "INSERT INTO Restaurant (id, content) VALUES (?, ?)"

let add_restaurant restaurant =
  let add_restaurant' id content (module C : Caqti_async.CONNECTION) =
    C.exec add_restaurant_query (id, content)
  in
  Caqti_async.Pool.use (add_restaurant' restaurant.id restaurant.content) pool

let check_restaurant_query =
  let open Caqti_request.Infix in
  let open Caqti_type in
  (string ->* tup2 string string) @@ "SELECT * FROM Restaurant WHERE id=?"

let check_restaurant restaurant_uri =
  let check_restaurant' id (module C : Caqti_async.CONNECTION) =
    C.collect_list check_restaurant_query id
  in
  Caqti_async.Pool.use (check_restaurant' restaurant_uri) pool

let get_restaurants_within_query =
  let open Caqti_request.Infix in
  let open Caqti_type in
  (tup3 float float float ->* tup2 string string)
  @@ {|select *
      from   restaurant z
      where  earth_distance(ll_to_earth(z.latitude, z.longitude),
      ll_to_earth(?, ?)) < ?; -- in meters  |}

let get_restaurants_within lat lon within =
  let get_restaurants_within' lat lon within (module C : Caqti_async.CONNECTION)
      =
    C.collect_list get_restaurants_within_query (lat, lon, within)
  in
  Caqti_async.Pool.use (get_restaurants_within' lat lon within) pool
