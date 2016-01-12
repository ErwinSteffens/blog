+++
date = "2016-01-11T11:03:52+01:00"
description = "How to migrate your existing .net project which uses NuGet packages to paket for better and easier package management."
tags = ["Development", "Paket", ".Net", "NuGet"]
categories = ["Development", ".Net"]
title = "Migrate your project from nuget to paket"
draft = true 
+++

For one of our projects we splitted up a big solutions by using NuGet packages. Therefore we became heavy users of NuGet and the NuGet tooling. We quickly became frustrated by using the NuGet tooling provided in Visual Studio because it is slow and there are some problems like:

* No 'Update All' method in the UI tooling
* No 'Update All' method for a specific source on the command line
* No transitive package reference. All package dependencies are listed in the project level packages.config file.
* No global versioning, but versioning per project. Package versions can drift within a solution.
 

We started looing for alternatives. We found [Paket](https://fsprojects.github.io/Paket/index.html) which is an dependency manager for .Net and mono projects. Paket can work with [NuGet](https://www.nuget.org/) packages, [Git](https://fsprojects.github.io/Paket/git-dependencies.html) repositories and [HTTP](https://fsprojects.github.io/Paket/http-dependencies.html) resources. More information about why Paket is better can be found here: http://fsprojects.github.io/Paket/faq.html.

Paket has a good [migration guide](http://fsprojects.github.io/Paket/convert-from-nuget-tutorial.html) but we added some additional steps which I will describe here.

## Convert from NuGet

Paket has an `convert-from-nuget` command which converts a solution from NuGet tooling to Paket. Execute the fooling step in your solution directory to get started:

* Download the paket bootstrapper from [here](https://github.com/fsprojects/Paket/releases/tag/2.42.3) and copy it into a `.paket` directory in your solution directory.
* Run the bootstrapper by entering `.paket\paket.bootstrapper.exe`. This will download the latest `paket.exe` file.
* Commit `.paket/paket.bootstrapper.exe` into your repositry and add `paket.exe` to your `.gitignore` file.

## Remove transitive dependencies

## Setup authorization

## Replace .nuspec files

## Finishedß