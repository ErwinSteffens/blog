+++
date = "2017-01-25T20:25:28+01:00"
tags = ["Gulp","Dotnet","Core","Watch"]
categories = ["Development"]
description = "Use gulp watch to automatically rebuild a .NET core project on a file change"
title = "Gulp watch and dotnet run"
+++

With the new .NET Core ans ASP.NET versions, the future for .NET looks promising. It allows for creating your C# .NET project outside the Visual Studion environment. With the release of [Visual Studio Code](https://code.visualstudio.com/) we have a great new option for developing your project. Visual Studio is a great IDE, but we think it is a little bloated at the moment. Adding ReSharper to the package and you have long start-up times and annoying delays. we hope a lot of this will get fixed in VS2017!!

For a recent web project we started using .NET core. At the moment of writing this was the `preview 2` version. There were already some newer versions, but the `preview 2` proved to be pretty stable to us. Because of our irritations with VS, we started to investigate VS Code. VS Code is a very neat and fast editor for your web projects. 

Developing with .NET means always rebuilding and restarting your project when you want to view some changes you made. The rebuilding only affects `.cs` and `.resx` files. `.cshtml` files are automatically recompiled when loading a new view. The rebuild process seriously started to slow down development. This became a little annoying, so we started to investigate some options.

Dotnet offers a tool called `dotnet watch` (https://github.com/aspnet/DotNetTools). This looks very promising! The only thing is; `preview 2` crashes on `.resx` files ?!?! So, what's next? Almost everybody who has done some web development, knows `gulp` and the `gulp-watch` package. This is very useful for preparing your web assets. We already used it for our `sass` scripts and when we integrate it with serving the `dotnet` project, we have a single command for running the project.

Combining the `gulp-watch` with spawning a `dotnet run` command results in the following gulp script:

```javascript
var gulp = require('gulp'),
  gutil = require('gulp-util'),
  spawn = require('child_process').spawn,
  kill = require('tree-kill'),
  server

gulp.task('watch:dotnet', ['serve:dotnet'], function () {
  gulp.watch([
    './**/*.resx',
    './**/*.cs',
    '!./bin/**/*',
    '!./obj/**/*',
  ], {
    interval: 250
  }, ['run:dotnet']).on('change', function (event) {
    gutil.log(`File ${event.path} was ${event.type}, running tasks...`)
  })
})

gulp.task('serve:dotnet', function () {
  if (server) {
    kill(server.pid)
  }

  server = spawn('dotnet', ['run'], {
    stdio: 'inherit'
  })

  server.on('close', function (code) {
    if (code === 8) {
      gutil.log('Error detected, waiting for changes...')
    }
  })
})
```

There are two tasks in here:

## watch:dotnet

This first starts the `serve:dotnet` for initially starting the `dotnet run`. Then it start the `gulp-watch` task for checking for file changes, ignoring the build outputs. After this it triggers the `serve:dotnet` task on each file change. 

## serve:dotnet

This checks if there was already a spawned process. When there is, it is killed. We use the `tree-kill` package here, because `dotnet run` spawns another sub-process (see https://github.com/dotnet/cli/issues/1327) which also needs to be killed. After this we spawn a new `dotnet run` process which builds and runs the project.