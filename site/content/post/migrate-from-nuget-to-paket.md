+++
date = "2016-01-11T11:03:52+01:00"
description = "How to migrate your existing .net project which uses NuGet packages to paket for better and easier package management."
tags = ["Development", "Paket", "Dotnet", "NuGet"]
categories = ["Development"]
title = "Migrate your project from nuget to paket" 
+++

For one of our projects we splitted up a big solutions by using NuGet packages. Therefore we became heavy users of NuGet and the NuGet tooling. We quickly became frustrated by using the NuGet tooling provided in Visual Studio because it is slow and there are some problems like:

* Problems with using 'Update All' method in the UI tooling and command line.
* No transitive package reference. All package dependencies are listed in the packages.config file. Also dependencies of dependencies of dependencies. When you want to remove a dependency, you also have to figure out all the sub-dependecies that can be removed.
* No global versioning, but versioning per project. Package versions can drift within a solution.

We started looing for alternatives and found [Paket](https://fsprojects.github.io/Paket/index.html). Paket is a dependency manager for .Net and mono projects. Paket can work with [NuGet](https://www.nuget.org/) packages, [Git](https://fsprojects.github.io/Paket/git-dependencies.html) repositories and [HTTP](https://fsprojects.github.io/Paket/http-dependencies.html) resources. More information about why Paket is better than NuGet can be found [here](http://fsprojects.github.io/Paket/faq.html).

Paket has a good [migration guide](http://fsprojects.github.io/Paket/convert-from-nuget-tutorial.html) but we added some additional steps which I will describe here.
<!--more-->

## Convert from NuGet

Paket has an `convert-from-nuget` command which converts a solution from NuGet tooling to Paket. Execute the following step in your solution folder to get started:

* Download the `paket.bootstrapper.exe` file from [here](https://github.com/fsprojects/Paket/releases/tag/2.42.3) and copy it into a `.paket` folder in your solution folder.
* Run the bootstrapper by entering `.paket\paket.bootstrapper.exe`. This will download the latest `paket.exe` file.
* Commit `.paket/paket.bootstrapper.exe` into your repositry and add `paket.exe` to your `.gitignore` file.

> The `convert-from-nuget` command copies the auto-restore setting from your NuGet configuration. If you want to enable/disable auto-restore use the `auto-restore` command. More info [here](https://fsprojects.github.io/Paket/paket-auto-restore.html).

## Remove transitive dependencies

One of the best features of Paket is that you do not have to specify transitive dependencies in your package configuration. When using NuGet all your transitive dependencies are added to the `packages.config` file. When using the `convert-from-nuget` command all the packages (include all transitive dependencies) in the `packages.config` file are added to the `paket.dependencies` file. To remove transitive dependencies you can use the 'simplify' command. We prefer to select the dependencies to remove ourself. You can do this using the `--interactive` flag:

`.\.paket\paket.exe simplify --interactive`  

Select the dependencies you want to keep or remove.

## Clean-up dependencies file

We do not like the content option which automaticly adds package content to your projects. You can disable this by adding `content: none` to your `paket.dependencies` file. When you want to add the content of a package to your project, add `content: once` behind the reference in the `paket.references` file of the project.

Paket can also create assembly redirects in your project files when installing new packages. To enable this feature add `redirects: on` to your `paket.dependencies` file.

When using NuGet, the package versions in the `packages.config` file are mostly fixed to a specific version. To be able to use the `outdated` and `update` commands of Paket it is better to allow a specific version range for a package.  We mostly use the `~>` operator to select a version range. This allows minor updates or patches to be used, but does not allow the major version number to be changed. More information about version restrictions can be found [here](https://fsprojects.github.io/Paket//dependencies-file.html). 

> When using a version range in your `paket.dependencies` file, this does not mean packages are automaticly updated on a package restore. You need to run the `update` command to install new available updates. The depedency graph which is chosen is stored in a [lock file](https://fsprojects.github.io/Paket//lock-file.html) called `paket.lock`.

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

This will ask for your credentials. Enter them and they will be stored somewhere in your `ApplicationData` folder. More info about this command can be found [here](https://fsprojects.github.io/Paket//paket-config.html).  

## Replace .nuspec files

Paket uses `paket.template` files for creating packages. To create a nuget package just add a `paket.template` file with `type project` as its content to each project folder. When running `paket pack` it will create a package for each `paket.template` file that is found in the solution. More information about the `paket.template` file can be found [here](https://fsprojects.github.io/Paket//template-files.html) and about the `paket pack` command can be found [here](https://fsprojects.github.io/Paket//paket-pack.html).

> When a project has a reference to another project that has a `paket.template` file, paket will automaticly replace the project reference with a package reference on the package that will be created for the referenced project. 

## Finished

Now your finished and you can start using the paket tooling for managing your NuGet packages. We like it very much and I hope this blog post helps you start up!