FROM perl:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN cpanm -qn App::rdapper
ENTRYPOINT ["/usr/local/bin/rdapper"]
