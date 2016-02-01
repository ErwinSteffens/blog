+++
date = "2016-01-20T21:36:17+01:00"
title = "Use paket with TeamCity"
description = "How to integrate package manager Paket into your TeamCity builds with PowerShell."
tags = ["Development", "TeamCity", "Paket"]
categories = ["Development", "TeamCity"]
+++

For a project I was working on we started migrating to [Paket](https://fsprojects.github.io/Paket/) for managing our NuGet dependencies. We use TeamCity as our CI environment. TeamCity has great support for using NuGet tooling, but there is no plugin for Paket.

Because we migrated to Paket we needed to modify our TeamCity build configurations so they still work. This post will describe how you can use Paket with TeamCity. It explains how to restore packages before building and how to publish created packages onto our NuGet feed. We use PowerShell and the `paket.exe` tool to do this.
<!--more-->

## Restore packages

Restoring packages is easy. Just call `paket.exe restore` and this will do the job. Another option is to enable `auto-restore` in your solution. This will add a `.target` file and will integrate the package restoring into your solution build. We do not want to depend on `auto-restore`. Developers can disable this for development as it speeds up the build process. We do not want to break the build when this is accidentily  disabled. Therefore we run a PowerShell script to restore the package on each build.

We use build configuration templates to manage the build process for multiple projects at once. Because we did not migrate all our projects to Paket directly we needed to restore packages by using the NuGet tooling and by using Paket. Therefore we test for the `.paket` folder by using `Test-Path .\.paket`. When the folder exists we know that we can restore packages by using Paket. 

We use a fixed version of Paket because it makes or build reproducable. New Paket versions are released on a daily basis and we do not want a new version of Paket to break our build. Consistent builds are the most important part of your development process. The `paket.exe` does [not need to be added](https://fsprojects.github.io/Paket/getting-started.html#Downloading-Paket-and-it-s-BootStrapper) to your repo. Therefore we use the `paket.bootstrapper.exe` for restoring the correct Paket version for us. The Paket version is specified in a TeamCity variable called `%paket.version%`. 

Add a PowerShell build step before your solution build step to your build configuration containing the following code which will execute all the steps above.

``` powershell
$paketVersion = %paket.version%

if (Test-Path .\.paket)
{
    // Download latest paket.exe
    & .\.paket\paket.bootstrapper.exe $paketVersion
    
    // Restore all packages
    & .\.paket\paket.exe restore
}
```

## Publish packages

Paket uses `paket.template` files for creating packages. When running the `pack` command, it will create packages for all `paket.template` files found in all subdirectories. We store the created packages in the `.\paket-pack-out` folder.

To publish the packages we just search for all packages in the `.\paket-pack-out` folder. Remember that TeamCity can re-use the working directory which still contains packages from previous builds. Therefore we search for packages with the version number of the current build to publish and push these packages onto our NuGet feed.

When you specify the `symbols` options, Paket will create symbols packages with a `.symbols.nupkg` extension. This will only happen for `paket.template` files which contain `type project`. Because we also create content packages which does not have a project origin, we check if a symbols package is created. When it is, we publish the symbols packages. When not, we publish the normal package.

Add a PowerShell build step after your solution build step containing the following code which will execute all the steps above.

``` powershell
$packageVersion = %build.number%
$nugetKey = %nuget.apiKey%
$nugetFeed = %nuget.publishFeed%
$buildConfig = %build.config%
$outputDir = ".\paket-pack-out"

if (Test-Path .\.paket)
{
    // Package all found paket.template files
    & .\.paket\paket.exe pack output $outputDir version $packageVersion `
        buildconfig $buildConfig symbols

    // Find all created packages
    Get-ChildItem "$outputDir\*.$packageVersion.nupkg" | % {
        $packagePath = $_
        
        // Check if a symbols package is created
        $symbolsPackagePath = $packagePath -replace ".nupkg",".symbols.nupkg"
        if (Test-Path $symbolsPackagePath)
        {
            $packagePath = $symbolsPackagePath
        }

        // Push the package to the feed
        & .\.paket\paket.exe push url $nugetFeed file $packagePath apikey $nugetKey 
    }
}
```

## Finished

These are the only steps to enable Paket on your TeamCity server. Hope this helps you speed-up your development!

> A better options is to add the powershell scripts to your repository and invoke them from the build step. This way you also have a fast way for restoring and publishing your packages on your local machine!