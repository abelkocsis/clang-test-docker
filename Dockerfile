FROM debian:stable-slim

ARG setup=TRUE
ARG run=TRUE
ARG projects="all"
ARG checker="all"
ARG deleteAfterAnalyse=FALSE

ENV setup ${setup}
ENV run ${run}
ENV projects ${projects}
ENV checker=${checker}
ENV deleteAfterAnalyse=${deleteAfterAnalyse}

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

RUN apt-get -yqq update

ADD . /opt/wd
WORKDIR /opt/wd

RUN bash install-deps.sh $setup $run $projects

CMD ["bash", "-c", "/testDir/clang-test-docker/start.sh ${setup} ${run} ${checker} ${deleteAfterAnalyse} ${projects}" ]
#TODO: ./start.sh

