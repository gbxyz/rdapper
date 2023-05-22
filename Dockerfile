FROM perl:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get upgrade -qqq
RUN cpanm -n App::rdapper
ENTRYPOINT ["/usr/local/bin/rdapper"]
