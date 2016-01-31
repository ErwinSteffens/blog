+++
date = "2016-01-20T21:36:17+01:00"
title = "Use paket with TeamCity"
description = "How to integrate package manager Paket into your TeamCity builds with PowerShell."
tags = ["Development", "TeamCity", "Paket"]
categories = ["Development", "TeamCity"]
draft = true
+++

For a project I was workign on we started migrating to [Paket](https://fsprojects.github.io/Paket/) for managing our NuGet dependencies. We needed to modify our TeamCity configurations so they still work. This post will describe how you can use Paket with TeamCity. To do this we need to restore packages before building starts and when needed we need to create new NuGet packages and publish them onto a feed. We use PowerShell and the `paket.exe` tool to do this.
<!--more-->

## Restore packages

Restoring packages is easy. Just call `paket.exe restore` and this will do the job. You can also enable `auto-restore` in your solution. This will add a `.target` file and will integrate the package restoring into your solution build. We do not want to depend on `auto-restore`. Developers can disable this for development as it speeds up the build process. We do not want to break the build when this is accidentily  disabled. Therefore we run a PowerShell script to restore the package on each build.

We use build configuration templates to manage the build process for multiple projects at once. Because we did not migrate all our projects to Paket directly we needed to restore packages by using the NuGet tooling and by using Paket. Therefore we test for the `.paket` folder by using `Test-Path .\.paket`. When the folder exists we know that we can restore packages by using Paket. 

We use a fixed version of Paket because it makes or build reproducable. New Paket versions are released on a daily basis and we do not want a new version of Paket to break our build. Consistant builds are the most important part of your development process. The Paket version is specified in a TeamCity variable called `%paket.version%`. The `paket.exe` does [not need to be added](https://fsprojects.github.io/Paket/getting-started.html#Downloading-Paket-and-it-s-BootStrapper) to your repo. Therefore we use the `paket.bootstrapper.exe` for restoring the correct Paket version for us. 

Add a PowerShell build step before your solution build step to your build configuration containing the following code which will execute all the steps above.

``` powershell
$paketVersion = %paket.version%

if (Test-Path .\.paket)
{
    // Download latest bootstrapper
    & .\.paket\paket.bootstrapper.exe $paketVersion
    
    // Restore all packages
    & .\.paket\paket.exe restore
}
```

``` powershell
$packageVersion = %build.number%
$nugetKey = %nuget.apiKey%
$nugetFeed = %nuget.publishFeed%
$buildConfig = %build.config%
$outputDir = ".\paket-pack-out"

if (Test-Path .\.paket)
{
    // Package all found paket.template files to the output directory 
    & .\.paket\paket.exe pack output $outputDir version $packageVersion `
        buildconfig $buildConfig symbols

    // Find all created packages
    Get-ChildItem "$outputDir\*.$packageVersion.nupkg" % {
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