FROM ubuntu:latest

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

#for curl
RUN apt-get -yqq update
RUN apt-get -yqq install git
RUN apt-get -yqq install autoconf libtool

ADD . /opt/wd
WORKDIR /opt/wd

RUN git clone https://github.com/curl/curl.git
WORKDIR /opt/wd/curl

RUN ./buildconf
RUN ./configure

