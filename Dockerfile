FROM perl:latest

RUN cpanm -qn File::ShareDir::Install App::rdapper

ENTRYPOINT ["/usr/local/bin/rdapper"]
