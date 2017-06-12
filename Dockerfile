FROM node:7
MAINTAINER Erwin Steffens <erwinsteffens@gmail.com>

RUN npm install http-server -g

ENV PORT 8080
ENV HUGO_VERSION 0.21
ENV HUGO_ARCHIVE hugo_${HUGO_VERSION}_Linux-64bit.tar.gz

ADD https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_ARCHIVE} /usr/local/
RUN tar xzf /usr/local/${HUGO_ARCHIVE} -C /usr/local/ \
	&& ln -s /usr/local/hugo_${HUGO_VERSION}_linux_amd64/hugo_${HUGO_VERSION}_linux_amd64 /usr/local/bin/hugo \
	&& rm /usr/local/${HUGO_ARCHIVE}

RUN mkdir -p /app

ADD ./site /app
WORKDIR /app

RUN hugo

EXPOSE $PORT

ENTRYPOINT ["http-server"]