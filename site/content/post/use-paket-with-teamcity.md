+++
date = "2016-01-20T21:36:17+01:00"
title = "Use paket with TeamCity"
description = ""
tags = ["Development", "TeamCity", "Paket"]
categories = ["Development", "TeamCity"]
draft = true
+++

For a project I was workign on we started migrating to [Paket](https://fsprojects.github.io/Paket/) for managing our NuGet dependencies. We needed to modify our TeamCity configurations so they still work. This post will describe how you can use Paket with TeamCity.