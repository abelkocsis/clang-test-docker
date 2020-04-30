FROM debian:stable-slim

ARG setup=TRUE
ARG run=TRUE
ARG checker="all"
ARG delete=FALSE
ARG projects="all"

ENV setup ${setup}
ENV run ${run}
ENV projects ${projects}
ENV checker=${checker}
ENV delete=${delete}
ENV list=FALSE

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

RUN apt-get -yqq update
RUN apt-get -yqq upgrade

ADD . /opt/wd
WORKDIR /opt/wd

RUN bash install-deps.sh $projects

CMD ["bash", "-c", "./start.sh ${setup} ${run} ${checker} ${delete} ${list} ${projects}" ]
