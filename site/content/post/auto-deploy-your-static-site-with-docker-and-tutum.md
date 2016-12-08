+++
title = "Auto deploy your static site with Docker and Tutum"
description = "Deploy your static website automatically after pushing to master by using Docker and Tutum."
date = "2015-12-09T22:10:38+01:00"
categories = ["Tutum", "CD"]
tags = ["Tutum", "CD", "Docker", "Hugo"]
+++

> DEPRECATED!
> Tutum is acquired by Docker and the Tutum service is re-branded to Docker Cloud. The concepts described in this post are still usable, but the content can be outdated.


When I decided to create my own blog I wanted to use a static site generator. Static sites are fast and secure and really cheap to host. There are great tools to built them and one of these tools is [Hugo](https://gohugo.io). Hugo is extremly easy to setup and is really fast. 

After searching for a docker deployment tool at my current job I came across [Tutum](https://tutum.co). Tutum is a great tool for building, deploying and managing docker containers. To get some experience with docker and Tutum I decided to automatically deploy my blog with Tutum.
<!--more-->

> Of course you can deploy every static site using the following steps. Just replace the hugo stuff with your own favorite tools.  

## Create blog/site

Hugo has very good documentation. There is a good quick start guide available here: https://gohugo.io/overview/quickstart/. Execute these steps and you will have your hugo blog ready in minutes!

Create your blog in a subfolder called 'site'. Your folder structure should look like this:  

	.
	├── Dockerfile
	└── site
	    ├── config.toml
	    ├── content
	    │   └── ...
	    ├── layouts
	    │   └── ...
	    └── static
		└── ...

## Hugo docker image

Docker volumes are persistant. As long as there is a container that references the volume it will be kept on the node. The best way of preserving your volume and data is to use [data volume containers](https://docs.docker.com/engine/userguide/dockervolumes/#creating-and-mounting-a-data-volume-container). This assures that the volume will not be deleted when this data container still exists.

My setup is as shown below. I've used a data container called 'site-data'. A container which holds the latest blog content called 'site-content' and a [nginx](https://github.com/nginxinc/docker-nginx) image for serving it. When the 'site-content' container is started the blog files will be copied into the data volume. This same data volume is used by nginx. By using this method you can update the 'site-content' container which will automatically redeploy the site.

``` bash
docker run -d -v /usr/share/nginx/html --name site-data debian:jessie true
docker run -d --volumes-from site-data --name site-content my/blog-image
docker run -d --volumes-from site-data --name site-server -p 80:80 nginx
```

> In my first setup I attached the volumes from the 'site-content' container directly. Docker does not apply changes to an existing data volume when you update an image ([see here](https://docs.docker.com/engine/userguide/dockervolumes/#data-volumes)) so the site was not updated when the 'site-content' container was updated. If you have any better suggestions for updating the data in a volume, please let me know.

I've created a [docker image](https://github.com/ErwinSteffens/docker-hugo) for generating the site content. It is largely based on the image created by [publysher](https://github.com/publysher/docker-hugo). You can use this image as a base image for your blog container. The commands in the Dockerfile install Hugo and run it for creating the static site files. The container start command removes existing files and copies the new files into the volume. 

``` Dockerfile
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
ONBUILD ADD site/ /usr/share/blog
ONBUILD RUN hugo

# Copy files to the nginx volume
CMD rm -rf /usr/share/nginx/html/*; \
    cp -r /usr/share/blog/public/* /usr/share/nginx/html; 
```

Create a Dockerfile in your blog repository which uses this image as its base. See https://github.com/ErwinSteffens/blog/blob/master/Dockerfile for an example. 

## Auto build your docker image

I chose to host my blog on DigitalOcean. They offer a basic VM for $5 a month which is more then enough for my site. Link a cloud provider to your account and create a new node cluster. This will provision one or more Tutum nodes in your cloud provider environment. 

> At the moment of writing DigitalOcean offers $20 dollar free credit when linking it to Tutum.

To build your blog content image create a new automated build in the repositories tab. Link your GitHub account and select the repository to build. Now open the repository and hit the 'Build' button to start the build. [Click here](https://support.tutum.co/support/solutions/articles/5000638474-automated-builds) for a detailed description about automated builds. 

Tutum will use one of your nodes for building the docker image. They use an 'emptiest node' strategy for selecting the node to use. When you want to select the build node by yourself you can assign the tag `builder` to the node.

When a build error occurs, open the repository in the Tutum UI and check the timeline. Here you can view the build logs. You can also setup an e-mail address to be notified on build errors.

## Stack setup

To run your services on Tutum you need to create a stack. A stack is a collection of services that make up an application in a specific environment. You can do this through the UI, but you can also define a stackfile. Stackfiles look like docker-compose files but they have some extra features. See the stackfile below for our setup. The `tags` field is optional. It is used for selecting the node to run this service on. When the `autoredeploy` field is set, Tutum will automaticly re-deploy this container when a new image is available in the repository, so this needs to be set for our blog-content container.

``` yml
blog-content:
  image: 'tutum.co/erwinsteffens/blog:latest'
  autoredeploy: true
  tags:
    - blog
  volumes_from:
    - blog-server-data
blog-server:
  image: 'nginx:latest'
  ports:
    - '80:80'
  tags:
    - blog
  volumes_from:
    - blog-server-data
blog-server-data:
  image: 'debian:jessie'
  command: 'true'
  tags:
    - blog
  volumes:
    - /usr/share/nginx/html
```

Create a new stack like this and replace the 'blog-content' image with your own image. When you have created the stack, hit the start button and the containers will be started by Tutum. 

## Finished

Your static site is running now! Test the auto-deploy by pushing a new update to your master branch and it will be build and deployed directly!