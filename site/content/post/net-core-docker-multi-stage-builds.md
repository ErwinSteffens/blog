+++
date = "2017-06-11T19:37:34+02:00"
description = "One of the best practices with using Docker is to keep your images small. This means you can better not include any code and build tools in your images. When using ASP.NET Core you can use the `dotnet publish` command for building and packaging your project. With Docker multi-stage builds these build commands can now be included into your Dockerfile which means a cleaner and more stable build process."
tags = ["Dotnet","Core","Docker","Multi-Stage"]
title = "Docker multi-stage builds with ASP.NET Core"
categories = ["Devops","Development"]
+++

One of the best practices with using Docker is to keep your images small. This means you can better not include any code and build tools in your images. When using ASP.NET Core you can use the `dotnet publish` command for building and packaging your project. With Docker multi-stage builds these build commands can now be included into your Dockerfile which means a cleaner and more stable build process.

> Notice that Docker multi-stage builds are available in the CE edition from version `17.05`! This means you need the Edge version which can be found [here](https://docs.docker.com/edge/).

The `publish` command builds the project and creates a folder containing all the output assemblies and the necessary dependencies needed to run your project. Running the `publish` command is mostly done outside the Docker environment on your local machine or on your CI agent. This means the output of the command depends on the configuration (and version of dotnet) of your local machine or CI agent. It would be much better if the `publish` command was executed in a consistent environment and the best tool for this would be in a docker image! 

There are already some great tools for doing this like [source2image](https://github.com/openshift/source-to-image) (s2i). S2i makes use of separate build images which contain the build chain and base images which will include the build output for running it in production. Luckily Docker has decided to include this functionality into their tooling and they named it multi-stage builds. You can read more about this functionality in this blog post: https://docs.docker.com/engine/userguide/eng-image/multistage-build/.

This post describes how to create a multi-stage build Dockerfile for an ASP.NET Core project:

## Create ASP.NET project

First create a new ASP.NET Core project by running the following command:

```bash
dotnet new mvc --name my-app --auth none
```

Now you have a brand new ASP.NET Core Mvc project. 

You can run it by executing:

```bash
cd ./my-app
bower install
dotnet restore
dotnet run 
```

## Creating a normal Dockerfile

You can now create a docker file by first publishing your project:

```bash
dotnet publish --output ./out
```

Now add the following Dockerfile in your root folder. When building this image it will include the published output:

```Dockerfile
FROM microsoft/dotnet:1.1-runtime
WORKDIR /dotnetapp
COPY out .
ENV ASPNETCORE_URLS "http://0.0.0.0:5000/"
ENTRYPOINT ["dotnet", "my-app.dll"]
```

You can run this image (and the next image below) by executing the following commands:

```
docker build -t my-app:latest .
docker run --rm -p 5000:5000 my-app:latest
```

## Using Docker multi-stage builds

Now let's create a multi-stage build Dockerfile.

With multi-stage builds you can repeat your `FROM` statements. Each `FROM` statement will begin a new stage of the build. This means all the previous layers are forgotten but you can select artifact to use from the previous build stages. Let's make a multi-stage Dockerfile:

```Dockerfile
FROM microsoft/aspnetcore-build:1.1 as publish
WORKDIR /publish
COPY .bowerrc bower.json ./
RUN bower install
COPY my-app.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish --output ./out

FROM microsoft/dotnet:1.1-runtime
WORKDIR /dotnetapp
COPY --from=publish /publish/out .
ENV ASPNETCORE_URLS "http://0.0.0.0:5000/"
ENTRYPOINT ["dotnet", "my-app.dll"]
``` 

So let's explain what happens here:

* The Dockerfile now includes two `FROM` statements. The first for building the project. 
* The first stage is named `publish`. The is done so you can reference to this stage from other build stages. The referencing can also done by using indexes.
* The last `FROM` statement start the final stage. This one is included in the final image.
* The `COPY --from builder` statement copies files from a previous build stage. 
* Because of docker [build caching](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#build-cache) the package dependencies are restored first by copying only the package file. This prevents the package restore process from being executed again when only a source file has been changed.

As you can see the multi-stage builds are a great way of including the build process in a Dockerfile. This means a better consistent and stable build process because the version and thus the environment of your build are included in your VCS when committing your changes. 
