FROM debian:jessie
MAINTAINER erwinsteffens@crosspoint.nl

# Download and install hugo
ENV HUGO_VERSION 0.15
ENV HUGO_BINARY hugo_${HUGO_VERSION}_linux_amd64
ADD https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY}.tar.gz /usr/local/
RUN tar xzf /usr/local/${HUGO_BINARY}.tar.gz -C /usr/local/ \
	&& ln -s /usr/local/${HUGO_BINARY}/${HUGO_BINARY} /usr/local/bin/hugo \
	&& rm /usr/local/${HUGO_BINARY}.tar.gz

# Create working directory
RUN mkdir /usr/share/blog
WORKDIR /usr/share/blog

# Automatically build site
ADD site/ /usr/share/blog
RUN hugo -d /usr/share/nginx/html

# Copy files to the nginx folder
CMD rm -rf /usr/share/nginx/html/*; \
    cp -r /usr/share/blog/public/* /usr/share/nginx/html