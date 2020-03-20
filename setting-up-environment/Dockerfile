FROM ubuntu:latest

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

#for curl
RUN apt-get -yqq update

ADD . /opt/wd
WORKDIR /opt/wd

RUN cat ./requirements_curl.txt | xargs apt-get -yqq install
RUN cat ./requirements_codechecker.txt | xargs apt-get -yqq install

WORKDIR /opt/wd

CMD ["bash", "./starting.sh" ]

