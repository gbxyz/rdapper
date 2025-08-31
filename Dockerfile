FROM perl:latest

RUN cpanm -qn File::ShareDir::Install

RUN cpanm -qn App::rdapper

ENTRYPOINT ["/usr/local/bin/rdapper"]
