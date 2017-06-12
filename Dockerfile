FROM node:7
MAINTAINER Erwin Steffens <erwinsteffens@gmail.com>

RUN npm install http-server -g

ENV HUGO_VERSION 0.21
ENV HUGO_ARCHIVE hugo_${HUGO_VERSION}_Linux-64bit.tar.gz

WORKDIR /tmp
ADD https://github.com/spf13/hugo/releases/download/v0.21/hugo_0.21_Linux-64bit.tar.gz /tmp
RUN mv /tmp/hugo /usr/local/bin/hugo && rm -rf /tmp/*

WORKDIR /app
ADD ./site /app

RUN hugo

EXPOSE 8080

ENTRYPOINT ["http-server"]