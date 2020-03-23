FROM alpine:latest

LABEL maintainer="Ábel Kocsis <kocsis.abel.98@gmail.com>"

#for curl
RUN apk update

ADD . /opt/wd
WORKDIR /opt/wd

RUN cat ./requirements_build_essentials.txt | xargs apk add --no-cache
RUN cat ./requirements_curl_alpine.txt | xargs apk add --no-cache
RUN cat ./requirements_codechecker_alpine.txt | xargs apk add --no-cache


WORKDIR /opt/wd

#CMD ["bash", "./starting.sh" ]

