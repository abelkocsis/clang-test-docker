FROM ubuntu:latest

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

RUN apt-get -yqq update

ADD . /opt/wd
WORKDIR /opt/wd

RUN cat ./requirements_codechecker.txt | xargs apt-get -yqq install

CMD ["bash", "./starting.sh" ]