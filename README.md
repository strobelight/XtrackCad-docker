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
* docker
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
After the first time, you should find XTrackCAD as an Application (under Graphics) and so drag to your toolbar for easy start. File associations are also put in place so that saved track plans can be double-clicked and worked on.

The directory `~/xtrkcad` on the host is your home directory in the container in which should be stored the track plans. As it's the home directory, you'll find other files here too that are specific to configuration changes you've made in the container.

Right-click in an empty spot and find a menu item for `XTrackCAD Doc` which brings up the contents.html file using firefox. The HELP menu in XTrackCAD will conflict as firefox apparently only allows one instance to run. If run via the Help menu, note that there's some sort of redraw problem as you wont see the XTrackCAD window being updated and dragging the browser over it shows the default X-window root background. I'm not sure where the issue is.

Here's what right-clicking in an empty portion of the window should look like:

![Image](https://github.com/user-attachments/assets/6a7af21e-526c-4107-9928-ed1247fa132b)

Output is also captured in /tmp/startxtrkcad.log.

## Debug
If the X window opens and closes during startup, something is wrong, 😉.

This information is provided here since I can't remember all the steps I do to troubleshoot. You may find this useful too if you dare to dive into the weeds of X11 and containers.

Here's some basic manual steps that `x11docker` basically does (there's lots more it does, but this helps narrow down where the problem might be):

```
# vars
export XTRK_VER=5.3.0
export DOCKER_USER=$USER

# open empty X window on current display
Xephyr :101 -screen 1920x1280 -retro &

# if errors on start of Xephyr
# rm -rf /tmp/.X11-unix/X101

# run container (presumes pulseaudio)
docker run --rm -d  --name xtrkcad --network host --privileged -v /run/user/1000/pulse/native:/tmp/pulseaudio.socket.host -e PULSE_SERVER="unix:/tmp/pulseaudio.socket.host" -v /run/cups:/run/cups -e CUPS_SERVER=/run/cups/cups.sock -e DISPLAY=:101 -v /tmp/.X11-unix/X101:/tmp/.X11-unix/X101 -v $HOME/xtrkcad:/home/$DOCKER_USER xtrkcad:$XTRK_VER bash

# if that fails, try (presumes pulseaudio)
docker run --rm -it  --name xtrkcad --network host --privileged -v /run/user/1000/pulse/native:/tmp/pulseaudio.socket.host -e PULSE_SERVER="unix:/tmp/pulseaudio.socket.host" -v /run/cups:/run/cups -e CUPS_SERVER=/run/cups/cups.sock -e DISPLAY=:101 -v /tmp/.X11-unix/X101:/tmp/.X11-unix/X101 -v $HOME/xtrkcad:/home/$DOCKER_USER xtrkcad:$XTRK_VER bash

# any errors here means container is corrupt and needs to be rebuilt

# if you get a prompt enter:
xeyes

# hopefully some eyes appear on the X window which follow the mouse
# ctrl-c to quit

# start the window manager and then xeyes
startfluxbox >/dev/null 2>&1 &
xeyes

# this time the eyes are in a window which can be moved around with the mouse
# close xeyes

# try xtrkcad
xtrkcad

# if that works, quit the program (File -> Exit)

# quit fluxbox
pkill -f fluxbox

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
