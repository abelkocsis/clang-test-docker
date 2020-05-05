FROM debian:stable-slim

ARG setup=TRUE
ARG analyze=TRUE
ARG checkers="all"
ARG delete=FALSE
ARG projects="all"

ENV setup ${setup}
ENV analyze ${analyze}
ENV projects ${projects}
ENV checkers=${checkers}
ENV delete=${delete}
ENV list=FALSE

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

RUN apt-get -yqq update
RUN apt-get -yqq upgrade

ADD . /opt/wd
WORKDIR /opt/wd

RUN bash install_deps.sh $projects

CMD ["bash", "-c", "./start.sh ${setup} ${analyze} ${checkers} ${delete} ${list} ${projects}" ]
