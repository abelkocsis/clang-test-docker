FROM debian:stable-slim

ARG setup=TRUE
ARG run=TRUE
ARG projects=curl

ENV setup ${setup}
ENV run ${run}
ENV projects ${projects}

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

RUN apt-get -yqq update

ADD . /opt/wd
WORKDIR /opt/wd

RUN bash setup-deps.sh $setup $run $projects

CMD ["bash", "-c", "./start.sh ${setup} ${run} ${projects}" ]

