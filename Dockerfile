FROM ocaml/opam:alpine-3.14-ocaml-4.14 as build

RUN sudo apk add --no-cache libev-dev m4 linux-headers gmp-dev perl postgresql-dev

ADD travelguide.opam .
RUN opam install . --deps-only

ADD . .
RUN sudo chown -R opam:nogroup . && eval $(opam env) && dune build --build-dir /home/opam/build

FROM alpine:3.14

COPY --from=build /home/opam/build/default/bin/travelguide.exe app.exe

RUN  apk add --no-cache libev-dev m4 linux-headers gmp-dev perl postgresql-dev

CMD ./app.exe --port=$PORT