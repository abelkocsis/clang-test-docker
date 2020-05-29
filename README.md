# Clang Test Docker (CTD)

Clang Test Docker is a tool to test new Clang-Tidy checkers automatically on open source projects. It is based on [Docker](https://www.docker.com) and [CodeChecker](https://github.com/Ericsson/codechecker). It automatically downloads, configures, builds projects and runs [LLVM Clang-Tidy](https://clang.llvm.org/extra/clang-tidy/) on the projects with CodeChecker.

In order to do this, CTD downloads specified projects in a specified folder to the local folder, and installs these projects requirements in a container. After that, the container runs the necessary operations. You also have the chance to add new projects or delete projects to CTD.

## Requirements

Before using Clang Test Docker, you need to install [Docker](https://www.docker.com) to your computer and make sure that you have the permissions to build image and run a container using Docker. You also need to [build your own LLVM](https://llvm.org/docs/CMake.html). Note that you have to build llvm to your `llvm-project/build` folder, unless CTD will not work.

## How to use

First of all, you should clone this repository.

```
$ git clone https://github.com/abelkocsis/clang-test-docker.git
```

### Using containers

It is important to understand the basic use of containers. If you have never heard about container techonolgy, it is recommended to read [this page](https://docs.docker.com/get-started/overview/). If you have learnt the basics (building image, running container), you are ready to go forward.

Tee architecture of CTD will be available soon.

### Building an image

You can build an image from the CTD home folder. 

Recommended building for beginners:

```
$ docker build -t <your_image_name> .
```

You have the opportunitiy to add different arguments when building a container with the following code:

```
$ docker build -t <your_image_name> . \
>   --build-arg <builArg1Nev>=<buildArg1Ertek> \
> --build-arg <builArg2Nev>=<buildArg2Ertek> \
...
```

The following build-ags can be added:

| Argument              | Available values        | Default value         | Description                             |
| ----------------------|-------------------------|-----------------------|-----------------------------------------|
| setup                 | TRUE / FALSE              | TRUE                  | Run the setup on default                |
| analyze                 | TRUE / FALSE              | TRUE                  | Run the analyzis on default                |
| projects               | all / Name of projects separated by comma | all  | Which projects should be configured and analyzed|
| checkers                 | all / Name of checkers separated by comma              | all                  | Default checkers                |
| delete                 | TRUE / FALSE              | FALSE                  | After running the abovemntioned operations, automatically delete the folders of the projects                |

Note that the container will be based on the image you biuld. This means that you must specify all projects you would like to analyze. You will not be able to add new projects to analyzis without building a new image.

### Building an image example

Create an image, which will be able to set up the bitcoin and curl projects and the analyze it with the bugprone-bad-signal-to-kill-thread checker.

```
$ docker build -t test-bit-and-curl . \
> --build-arg checkers=bugprone-bad-signal-to-kill-thread \
> --build-arg projects=bitcoin,curl
```

### Available projects

There are numerous projects which can be tested by CTD. These are the following:
[bitcoin](https://github.com/bitcoin/bitcoin.git),
[ffmpeg](https://git.ffmpeg.org/ffmpeg.git),
[nginx](https://github.com/nginx/nginx.git),
[postgres](https://github.com/postgres/postgres.git),
[redis](https://github.com/antirez/redis.git),
[tmux](https://github.com/tmux/tmux.git),
[openssl](https://github.com/openssl/openssl.git),
[git](https://github.com/git/git.git),
[vim](https://github.com/vim/vim.git),
[cpp-taskflow](https://github.com/cpp-taskflow/cpp-taskflow.git),
[enkiTS](https://github.com/dougbinks/enkiTS.git),
[RaftLib](https://github.com/RaftLib/RaftLib.git),
[FiberTaskingLib](https://github.com/RichieSams/FiberTaskingLib.git),
[curl](https://github.com/curl/curl.git),
[memcached](https://github.com/memcached/memcached.git).

Note that while building the image you can use projects names in the exactly same ways as it is mentioned above. So fibertskinglib of FiberTaskinlin will not woeking, only FiberTaskingLib.

### Running the container

You can run the container in the following way:

```
$ docker run \
>   -v <localDirToBuildProjects>:/testDir \
>   -v <localDirToLlvmProject>:/llvm-project \
>   <your_image_name>
```

In this way, all of the previously given (while building the image) operations will be done. The projects will be downloaded to your `<localDirToBuildProjects>`. The result of the analyzis will be available in your `<localDirToBuildProjects>/reports/<project_name>/html` folder in HTML format.

You are allowed to change the parameters while running the container in this way:

```
$ docker run \
>   -e "<arg1>=<value1>" \
>   -e "<arg2>=<value2>" \
...
>   <your_image_name>
```

The arguments are tha same as the building arguments. Note that you can run the analyzis and setup in less project than added while building the image, but you are not allowed to add new projects. Also note that setup is necessary before analyze the projects, but only once. So after runngin setup for all projects, you can disable it and run just the analyzis.

#### List all projects

If you have forgotten which projects are available in the container, you can list them. All other operations (setup, analyze) will not work.

```
$ docker run -e "list=TRUE" <your_image_name>
```

#### Setup and analyze projects

You can setup your projects setting the variable `-e "setup=TRUE"` and run the analyzis by `-e "analyze=TRUE"`.

Example: the destination of my working directory is saved on `testingRootDir` variable, nad my llvm directory is on `llvm` variable. So, I have prevously built a `test-clang` image. I would like to setup the projects without analyzing them.

```
$ docker run \
>   -e "setup=TRUE" \
>   -e "analyze=FALSE" \
>   -v $testingRootDir:/testDir \
>   -v $llvm:/llvm-project \
>   test-clang
```

The result of analyzis will be saved on my local container at `$testingRootDir/reports/<project_name>/html` folder.

### Add new projects

You can add a totally new project before building an imgage. To do this, you should run the `add_project.sh` script. This script helps you to do all the necessary steps. If you would like to skip a question simply hit enter.

### Delete projects

If have added a project not in the right way and would like to re-add it, you should delete a project. To do this, simply tun `delete_project.sh`. Note that after that, no image will be able to use the project you have deletet.

## Warnings and errors

Will be availale soon.
