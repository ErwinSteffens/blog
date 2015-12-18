+++
title = "Auto deploy your static site with Docker and Tutum"
description = "Deploy your static website automatically after pushing to master by using Docker and Tutum."
date = "2015-12-09T22:10:38+01:00"
categories = ["tutum", "cd"]
tags = ["tutum", "cd", "docker", "hugo"]
draft = true
+++

When I decided to create my own blog I wanted to go for a static site generator. Static sites are fast and secure and really cheap to host. For a developer they are easy to built and a great tool for doing this is [Hugo](https://gohugo.io). Hugo is extremly easy to setup and is really fast. 

After searching for a docker deployment tool at my current job I came across [Tutum](https://tutum.co). Tutum is a great tool for building, deploying and managing docker containers. To get some experience with docker and Tutum I decided to automaticly deploy my blog with Tutum.

> Of course you can deploy each static site using the following steps. Just replace the hugo stuff with your own favorite tool.  

## Create blog/site

Hugo has very good documentation. There is a good quick start guide available here: https://gohugo.io/overview/quickstart/. Execute these steps and you will have your hugo blog will be ready in minutes!

Create your blog in a subfolder called 'site'. It should look like this: 

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

## Hugo docker file

I've created a [docker image](https://github.com/ErwinSteffens/docker-hugo) for generating the site content. It is largely based on the image created by [publysher](https://github.com/publysher/docker-hugo). You can use this image as a base image for your blog. 

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

# Copy files to the nginx folder
CMD rm -rf /usr/share/nginx/html/*; \
    cp -r /usr/share/blog/public/* /usr/share/nginx/html; 
```

Create a Dockerfile in your blog repository which uses this image as its base. See https://github.com/ErwinSteffens/blog/blob/master/Dockerfile for an example. 

## Auto build your docker image

I chose for hosting my blog on DigitalOcean. They offer a basic VM for $5 a month which is more then enough to serve my site. Link a cloud provider to your account and create a node cluster. This will provision one or more Tutum nodes in your cloud provider environment. 

> Tutum will use one of your nodes for building the docker image. They use a `emptiest node` strategy to select the node to use. When you want to select the build node by yourself you can assign the tag `builder` to the node.

To build your blog content image create a new automated build in the repositories tab. Link your GitHub account and select the repository to build. Now open the repository and hit the 'Build' button to start the build. [Click here](https://support.tutum.co/support/solutions/articles/5000638474-automated-builds) for a detailed description about automated builds. 

> At the moment of writing DigitalOcean offers $20 dollar free credit when linking it to Tutum.

## Stack setup

Docker volumes are persistant. As long as there is a container that references the volume it will be kept on the node. The best way of preserving your volume and data is sto use [data volume containers](https://docs.docker.com/engine/userguide/dockervolumes/#creating-and-mounting-a-data-volume-container). They assure that the volume will not be deleted when this container still exists.

My setup is as shown below. I've used a data container called 'site-data'. A container which holds my 'site-content' and an [nginx](https://github.com/nginxinc/docker-nginx) image for serving it. When the 'site-content' is container is started the new files will be copied into the data volume. The data volume is used by nginx to serve the site. By using this method you can update the 'site-content' container which will redeploy the site.

``` bash
docker run -d -v /usr/share/nginx/html --name site-data debian:jessie true
docker run -d --volumes-from site-data --name site-content my/blog-image
docker run -d --volumes-from site-data --name site-server -p 80:80 nginx
```

> In my first setup I attached the volumes from the 'site-content' container directly. Docker does not apply changes to a data volume when you update an image ([see here](https://docs.docker.com/engine/userguide/dockervolumes/#data-volumes)). If you have any better suggestions for doing this, please let me know.

To run your services on Tutum you need to create a stack. A stack is a collection of services that make up an application in a specific environment. You can do this through the UI by clicking it together, but you can also define a stackfile. Stackfiles look like docker-compose files but they have some extra features. See the stackfile below for our setup. The `tags` field is optional. It is used for selecting the node to run this service on. When the 'autoredeploy' field is set, Tutum will automaticly re-deploy this container when a new image is available in the repository.

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

### Test it
