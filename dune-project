(lang dune 3.2)

(using dune_site 0.1)

(name travelguide)

(authors "Matheus Bernardo")

(maintainers "matheussbernardo@gmail.com")

(homepage "https://github.com/zeguide/restaurants_crawler")

(bug_reports "https://github.com/zeguide/restaurants_crawler/issues")

(generate_opam_files true)

(package
 (name travelguide)
 (synopsis "TELEGRAM BOT")
 (description "TELEGRAM BOT")
 (depends
  (ppx_show
   (>= 0.2.1))
  (ppx_yojson_conv
   (>= v0.15.0))
  (caqti
   (>= 1.8.0))
  (caqti-async
   (>= 1.8.0))
  (caqti-driver-postgresql
   (>= 1.8.0))
  (yojson
   (>= 1.7.0))
  (lambdasoup
   (>= 0.7.3))
  (cohttp-async
   (>= 5.0.0))
  (core
   (>= v0.15.0))))
