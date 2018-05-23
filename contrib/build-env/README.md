# Docker based ONIE Build Environment

This Dockerfile creates a Debian 9 (stretch) build environment for
ONIE.  The goal is to access a shell session as the 'build' user
within the container environment and compile ONIE images.

This example also clarifies how Docker could be used in a build
workflow.

Docker allows you to package an entire Linux environment into units
called containers. Containers utilise [control
groups](https://en.wikipedia.org/wiki/Cgroups "Wikipedia Cgroups"), a
resource isolation & management feature of the Linux kernel, to
execute their processes with allowances specific to their control
group.

## Container Preparation

Install docker.io on your host system.  This varies by distribution,
but for a Debian based system this looks like:
```
user@host:~$ sudo apt-get update
user@host:~$ sudo apt-get install docker.io`
```

You may need to add your user id to the `docker` group.
```
user@host:~$ sudo adduser $USER docker
```

For that to take effect you have to logout and login again.
Alternatively use `su - $USER` to avoid logging out.

Build the image using Docker.  From the same directory as the
Dockerfile run this:
```
user@host:~/src/onie/contrib/build-env$ docker build -t debian:build-env .
```

> Note: Should you want to rebuild the docker image after changing the
> Dockerfile do this:
* `docker stop onie`
* `docker rm onie`

Then run `docker build ...` again.

Create a build directory on the host system that will be accessible
from within the docker container.  Make sure the directory is
write-able by the docker `build` user.

```
user@host:~$ mkdir --mode=0777 -p ${HOME}/src
```

This directory will be availabe from within the container as
`/home/build/src`.

## Login to Container

Create a container from this image, and attach your terminal onto it.

```
user@host:~$ docker run -it -v ${HOME}/src:/home/build/src --name onie debian:build-env
```

The name of this container is `onie`.  You can use this name with the
docker commands.

After run the container, you should see a prompt that looks similar to
this:

```
build@f1063a996da6:~$
```

> Note: Should you find yourself detached from your container
> instance, you can use `docker attach onie` to re-attach onto a
> running container.

## Build Preparation
As the `build` user, clone the ONIE repo using the provided
`clone-onie` script:

```
build@f1063a996da6:~$ ./clone-onie
```

This clones the ONIE repo into `/home/build/src/onie`.

Navigate to the ONIE build-config directory.

```
build@f1063a996da6:~$ cd src/onie/build-config
build@f1063a996da6:~/src/onie/build-config$
```

## Building ONIE
You are now ready to follow a target's build steps from the ONIE repository.

Please review the 'INSTALL' file within a directory you'll find [here](https://github.com/opencomputeproject/onie/tree/master/machine "onie/machines").

* For a KVM build: `make -j4 MACHINE=kvm_x86_64 all`

* For an Accton platform: `make -j4 MACHINEROOT=../machine/accton MACHINE=accton_as7816_64x all`

On the host system the ONIE build products are available in
`${HOME}/src/onie/build/images`.

```
user@host:~$ ls -l ${HOME}/src/onie/build/images
total 55116
-rw-r--r-- 1 1000 1000  7557500 Apr  4 12:37 kvm_x86_64-r0.initrd
-rw-r--r-- 1 1000 1000  3917760 Apr  4 12:35 kvm_x86_64-r0.vmlinuz
-rw-r--r-- 1 1000 1000  3915856 Apr  4 12:35 kvm_x86_64-r0.vmlinuz.unsigned
-rw-r--r-- 1 1000 1000 28704768 Apr  4 12:38 onie-recovery-x86_64-kvm_x86_64-r0.iso
-rw-r--r-- 1 1000 1000 12330871 Apr  4 12:37 onie-updater-x86_64-kvm_x86_64-r0
```

## Caveats

### .gitconfig

The initial docker environment sets up a fake .gitconfig, defaulting
to the name `Build User` with email `build@example.com`.  For serious
development you will want to changes these to legitimate values.

### user / group IDs

The build user and group IDs within the container will not make sense
when viewed from the host environment.  This is why the build
directory is created with world writable permissions.
