+++
title = "Auto deploy your static site with Docker and Tutum"
description = "Deploy your static website automatically after pushing to master by using Docker and Tutum."
date = "2015-12-09T22:10:38+01:00"
categories = ["tutum", "cd"]
tags = ["tutum", "cd", "docker", "hugo"]
draft = true
+++

Because I get a lot of usefull help from people writing blogs I decided to start writing my one blog. My idea is to just write about the things I like and usefull tools I find during my development work. After playing around with different tools I decided to go for a static site generator because of the following advantages:

* Faster to serve
* Cheap hosting 
* Easy to manage
* Easy to version in Git
* Secure (No need to patch your CMS!)

There are a lot of great tools for generating a static website. I decided to use Hugo (https://gohugo.io/). Hugo is an extremly easy tool for building your blog/site from bunch of content files. The following features make it really great:

* Extremely fast build times
* Completely cross platform
* Easy installation 
* Render changes on the fly with LiveReload as you develop
* Complete theme support
* Integrated Disqus comment support
* Integrated Google Analytics support
* Syntax highlighting powered by Pygments 

I wanted to automatic deploy my blog when pushing to the master branch of this repo. For another personal project I was checking out docker and Tutum (https://www.tutum.co/). Tutum is a great tool for managing your docker containers and hosts. It can auto build and deploy your images. They can run on nodes hosted by cloud providers or you can bring yoru own node.

### Create blog

I can explain how to create your hugo blog, but hugo has very good documentation. There is a good quick start guide available here: https://gohugo.io/overview/quickstart/. Execute these steps and you will have your hugo blog will be ready!

> Create your blog in a subfolder (for example 'site'). This is easiear for the next step.

Next task is to push it to GitHub. I prefer using the commandline for this. Setup your ssh key in your github account (https://help.github.com/articles/generating-ssh-keys/), open the folder where you have created your blog and enter the following commands:

``` bash
echo 'public' > .gitignore
git init
git commit -m "Initial commit"
git remove add origin git@github.com:<your-account>/<your-repo>.git
git push -u origin master
```

When you know git this should be familiar. Now your blog content is stored on GitHub. Storing your blog it Git offers numurous advantages: 
* Complete history of all your changes
* You can create different branches for expirimenting with themes or content
* Backup

### Dockerize your hugo blog

A good way to serve static files is to use nginx. Docker provides a base image for nginx which can be found here: https://github.com/dockerfile/nginx. This image serves files from /usr/share/nginx/html. We will create a container which generates the blog files into a volume and attach the volumes from this container to the nginx container. The Dockerfile for this container looks like this:

``` dockerfile
FROM debian:wheezy
MAINTAINER Erwin Steffens <erwinsteffens@gmail.com>

# Install pygments (for syntax highlighting) 
RUN apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends python-pygments \
	&& rm -rf /var/lib/apt/lists/*

# Download and install hugo 
ENV HUGO_VERSION 0.15
ENV HUGO_BINARY hugo_${HUGO_VERSION}_linux_amd64
ADD https://github.com/spf13/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY}.tar.gz /usr/local/
RUN tar xzf /usr/local/${HUGO_BINARY}.tar.gz -C /usr/local/ \
	&& ln -s /usr/local/${HUGO_BINARY}/${HUGO_BINARY} /usr/local/bin/hugo \
	&& rm /usr/local/${HUGO_BINARY}.tar.gz

# Create working directory
RUN mkdir /usr/share/blog
ADD site /usr/share/blog
RUN hugo -s /usr/share/blog -d /usr/share/nginx/html
```

The file is based on the Dockerfile created by publysher (https://github.com/publysher/docker-hugo). The blog content output is stored into the `/usr/share/nginx/html` volume.

### Auto build your docker image

### Setup your Tutum stack

### Test it
