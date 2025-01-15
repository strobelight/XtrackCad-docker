# XtrackCad-docker

## Pre-requisites
* Xephyr
* xauth
* xclip
* xrandr
* xhost
* xinit
* xdpyinfo
* `curl -fsSL https://raw.githubusercontent.com/mviereck/x11docker/master/x11docker | sudo bash -s -- --update`

## Build xtrkcad container
Default build args (pass --build-arg=var=val for changes):
```
XTRK_VER=5.3.0
XTRK_REL=GA-1
XTRK_ARCH=x86_64
DOCKER_UID=1000
DOCKER_GID=1000
DOCKER_USER=$USER
```

To build:
```
export XTRK_VER=5.3.0
docker build -t xtrkcad:${XTRK_VER} --build-arg DOCKER_USER=$USER --build-arg XTRK_VER=$XTRK_VER .
```

## Run xtrkcad
If built with defaults:
```
export XTRK_VER=5.3.0
export DOCKER_USER=$USER
./startxtrkcad.sh
```
