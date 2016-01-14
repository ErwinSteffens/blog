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
 

We started looing for alternatives. We found [Paket](https://fsprojects.github.io/Paket/index.html) which is an dependency manager for .Net and mono projects. Paket can work with [NuGet](https://www.nuget.org/) packages, [Git](https://fsprojects.github.io/Paket/git-dependencies.html) repositories and [HTTP](https://fsprojects.github.io/Paket/http-dependencies.html) resources. More information about why Paket is better than NuGet can be found here: http://fsprojects.github.io/Paket/faq.html.

Paket has a good [migration guide](http://fsprojects.github.io/Paket/convert-from-nuget-tutorial.html) but we added some additional steps which I will describe here.

## Convert from NuGet

Paket has an `convert-from-nuget` command which converts a solution from NuGet tooling to Paket. Execute the fooling step in your solution directory to get started:

* Download the paket bootstrapper from [here](https://github.com/fsprojects/Paket/releases/tag/2.42.3) and copy it into a `.paket` directory in your solution directory.
* Run the bootstrapper by entering `.paket\paket.bootstrapper.exe`. This will download the latest `paket.exe` file.
* Commit `.paket/paket.bootstrapper.exe` into your repositry and add `paket.exe` to your `.gitignore` file.

> The `convert-from-nuget` command copies the auto-restore setting from your NuGet configuration. If you want to enable/disable auto-restore use the `auto-restore` command. More info [here](https://fsprojects.github.io/Paket/paket-auto-restore.html).

## Remove transitive dependencies

One of the best features of Paket is that you do not have to specify transitive dependencies in your package configuration. When using NuGet all your transitive dependencies are added to the `packages.config` file. When using the `convert-from-nuget` command all the packages in the `packages.config` file are added to the `paket.dependencies` file. To remove transitive dependencies you can use the 'simplify' command. We prefer to select the dependencies to remove by ourself. You can do this by running:

`.\.paket\paket.exe simplify --interactive`  

Select the dependencies you want to keep or remove in your `paket.dependencies` file.

## Clean-up dependencies file

We do not like the content option which automaticly adds package content to your projects. You can disable this by adding `content: none` to your `paket.dependencies` file.

Paket can also create assembly redirects in your project files when installing new packages. To enable this feature add `redirects: on` to your `paket.dependencies` file.

When using NuGet the package versions in the `packages.config` file are mostly fixed to a specific version. To be able to use the `outdated` and `update` commands of Paket it is better to allow a specific version range for a package. The depedency graph which is chosen when you use the update command is stored in a [lock file](https://fsprojects.github.io/Paket//lock-file.html) called `paket.lock`. We mostly use the `~>` operator to select a version range. This allows minor updates or patches to be used, but does not allow the major version number to be changed. More information about version restrictions can be found [here](https://fsprojects.github.io/Paket//dependencies-file.html).

Your `paket.dependencies` file now looks like this:

```
source https://nuget.org/api/v2

content: none
redirects: on

nuget NUnit ~> 2.6.3
nuget SourceLink.Fake
```  

## Setup authorization

When using authorized feeds you need to setup credentials for this feed. You can specify the credentials in your `paket.dependencies` file, but then they are added to your version control system and this is bad practice. A beter way is to specify the credentials on your system by using the `config` command. Run the following command to set the credentials:

`paket config add-credentials https://myfeed.mycompany.nl/nuget/default`

This will ask for your credentials. Enter them and they will be stored in somewhere in your `ApplicationData` folder. More info about this command can be found [here](https://fsprojects.github.io/Paket//paket-config.html).  

## Replace .nuspec files

## Finished