FROM debian:stable-slim

ARG mode="[setup,run]"
ARG procejts="[curl, git]"

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

RUN apt-get -yqq update
RUN apt-get install -yqq python-dev

ADD . /opt/wd
WORKDIR /opt/wd

RUN python setup-deps.py $mode $procejts
#RUN cat ./requirements_curl_debian.txt | xargs apt-get -yqq install
#RUN cat ./requirements_codechecker_debian.txt | xargs apt-get -yqq install

#CMD ["bash", "./starting.sh" ]

