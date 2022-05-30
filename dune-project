(lang dune 3.2)

(using dune_site 0.1)

(name travelguide)

(generate_opam_files true)

(package
 (name travelguide)
 (depends
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
