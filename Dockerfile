FROM nginx:1.13-alpine
MAINTAINER Erwin Steffens <erwinsteffens@gmail.com>

ENV HUGO_VERSION 0.21
ENV HUGO_ARCHIVE hugo_${HUGO_VERSION}_Linux-64bit.tar.gz

RUN apk update && \
    apk add ca-certificates wget

# Get and install hugo
WORKDIR /tmp
RUN wget https://github.com/spf13/hugo/releases/download/v0.21/hugo_0.21_Linux-64bit.tar.gz && \
    tar xzf hugo_0.21_Linux-64bit.tar.gz && \
    mv /tmp/hugo /usr/local/bin/hugo && \
    rm -rf /tmp/*

# Build the site with hugo
WORKDIR /build
COPY site /build
RUN hugo

# Copy build output to served folder
RUN mv /build/public/* /usr/share/nginx/html