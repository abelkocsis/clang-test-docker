FROM debian:stable-slim

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

#for curl
RUN apt-get -yqq update
#RUN apt-get install -yqq apt-utils

ADD . /opt/wd
WORKDIR /opt/wd

RUN cat ./requirements_curl_debian.txt | xargs apt-get -yqq install
RUN cat ./requirements_codechecker_debian.txt | xargs apt-get -yqq install


WORKDIR /opt/wd

#CMD ["bash", "./starting.sh" ]

