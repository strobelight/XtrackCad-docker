# XtrackCad-docker
This repo provides information on creating a docker container to run the XTrackCAD model railroad layout design program.

It makes use of [x11docker/xserver](https://hub.docker.com/r/x11docker/xserver) container as a base image.

## Pre-requisites
* Xephyr
* xauth
* xclip
* xrandr
* xhost
* xinit
* xdpyinfo
* `curl -fsSL https://raw.githubusercontent.com/mviereck/x11docker/master/x11docker | sudo bash -s -- --update-master`

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

## Debug
If the X window opens and closes during startup, something is wrong, :-;.

This information is provided here since I can't remember all the steps I do to troubleshoot. You may find this useful too if you dare to dive into the weeds of X11 and containers.

Here's some basic manual steps that `x11docker` basically does (there's lots more it does, but this helps narrow down where the problem might be):

```
# vars
export XTRK_VER=5.3.0
export DOCKER_USER=$USER

# open empty X window on current display
Xephyr :101 -screen 1920x1280 -retro &

# run container
docker run --rm -d --name xtrkcad -e DISPLAY=:101 -v /tmp/.X11-unix/X101:/tmp/.X11-unix/X101 -v $HOME/xtrkcad:/home/$DOCKER_USER xtrkcad:$XTRK_VER /startxtrkcad

# if that fails, try
docker run --rm -it  --name xtrkcad -e DISPLAY=:101 -v /tmp/.X11-unix/X101:/tmp/.X11-unix/X101 -v $HOME/xtrkcad:/home/$DOCKER_USER xtrkcad:$XTRK_VER bash

# any errors here means container is corrupt and needs to be rebuilt

# if you get a prompt enter:
xeyes

# hopefully some eyes appear on the X window which follow the mouse
# ctrl-c to quit

# start the window manager and then xeyes
openbox-session >/dev/null 2>&1 &
xeyes

# this time the eyes are in a window which can be moved around with the mouse
# close xeyes

# try xtrkcad
xtrkcad

# if that works, quit the program (File -> Exit)

# quit openbox
pkill -f openbox

# if you have gotten this far, the pieces work manually so something up with the x11docker script.
./startxtrkcad.sh -v

# above runs x11docker as follows:
x11docker -V --keepcache --home=$HOME/xtrkcad --xephyr --user=$DOCKER_USER --desktop --size=1920x1280 --name=xtrkcad xtrkcad:${XTRK_VER} /startxtrkcad.sh

# the --keepcache will not automatically remove the session cache directory
# see ~/.cache/x11docker/*xtrkcad* directories

# try xtrkcad start script
/startxtrkcad.sh

# docker command used can be found in the cache directory, provided the --keepcache option passed
cat ~/.cache/x11docker/*xtrkcad*/docker.command

# the ~/.cache/x11docker/*xtrkcad*/share directory has the log and scripts used by x11docker
# mounted to /x11docker in container
```
