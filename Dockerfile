FROM nginx:1.13
MAINTAINER Erwin Steffens <erwinsteffens@gmail.com>

ENV HUGO_VERSION 0.21
ENV HUGO_ARCHIVE hugo_${HUGO_VERSION}_Linux-64bit.tar.gz

WORKDIR /tmp
ADD https://github.com/spf13/hugo/releases/download/v0.21/hugo_0.21_Linux-64bit.tar.gz /tmp
RUN mv /tmp/hugo /usr/local/bin/hugo && rm -rf /tmp/*

WORKDIR /build
COPY site /build
RUN hugo

RUN mv /build/public/* /usr/share/nginx/html