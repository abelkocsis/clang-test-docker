FROM ubuntu:latest

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

#for curl
RUN apt-get -yqq update
RUN apt-get -yqq install git

ADD . /opt/wd
WORKDIR /opt/wd

RUN cat ./requirements_curl.txt | xargs apt-get -yqq install

RUN git clone https://github.com/curl/curl.git
WORKDIR /opt/wd/curl

RUN ./buildconf
RUN ./configure

