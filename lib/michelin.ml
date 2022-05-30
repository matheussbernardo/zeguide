open Core

type restaurant = { id : string; content : string }
[@@deriving yojson, sexp, show, compare]

let parse_page page_str =
  Soup.parse page_str
  |> Soup.select ".restaurant__list-row a.link"
  |> Soup.to_list
  |> List.map ~f:(fun node -> Soup.attribute "href" node |> Option.value_exn)

let parse_restaurant body_str =
  let content =
    Soup.parse body_str
    |> Soup.R.select_one {|[type=application/ld+json]|}
    |> Soup.R.leaf_text
  in
  let open Yojson.Basic.Util in
  let url = content |> Yojson.Basic.from_string |> member "url" |> to_string in
  let id =
    String.substr_replace_all url ~pattern:"https://guide.michelin.com"
      ~with_:""
  in
  { id; content }
