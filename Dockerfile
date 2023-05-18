FROM perl:latest
RUN apt-get update
RUN cpanm -n App::rdapper
ENTRYPOINT ["/usr/local/bin/rdapper"]
