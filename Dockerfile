FROM perl:latest

RUN cpanm -qn App::rdapper

ENTRYPOINT ["/usr/local/bin/rdapper"]
