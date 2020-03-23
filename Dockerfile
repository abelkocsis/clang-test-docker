FROM debian:stable-slim

ARG setup=TRUE
ARG run=TRUE
ARG projects=curl,clang,llvm

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

RUN apt-get -yqq update

ADD . /opt/wd
WORKDIR /opt/wd

RUN bash setup-deps.sh $setup $run $projects
#RUN cat ./requirements_curl_debian.txt | xargs apt-get -yqq install
#RUN cat ./requirements_codechecker_debian.txt | xargs apt-get -yqq install

#CMD ["bash", "./starting.sh" ]

