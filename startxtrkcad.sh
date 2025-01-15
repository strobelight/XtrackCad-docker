#!/bin/bash
ME=$(basename $0)

#####################################################################
#   directory to mount to container for saving of xtrkcad data
#   (preferences, track plans, etc.)
#####################################################################
XTRKCAD_DATADIR=${XTRKCAD_DATADIR:-$HOME/xtrkcad}

#####################################################################
#   docker user
#####################################################################
DOCKER_USER=${DOCKER_USER:-$USER}

#####################################################################
#   xtrkcad version
#####################################################################
XTRK_VER=${XTRK_VER:-5.3.0}

#####################################################################
# start xtrkcad
#####################################################################

exec 2>&1

#####################################################################
#   R U N N I N G   I N   D O C K E R   C H E C K
#####################################################################
running_in_docker() {
    [[ -f /.dockerenv ]] && return
    [[ -f /proc/self/cgroup ]] || return
    grep docker /proc/self/cgroup
}

#####################################################################
#   X T R K C A D   S E T U P
#####################################################################
xtrkcad_init() {
# do not install everytime container run
    [[ -f ~/Desktop/xtrkcad.desktop ]] && return
    /usr/share/xtrkcad/xtrkcad-setup install /usr/share/xtrkcad/
    chmod +x ~/Desktop/xtrkcad.desktop
    mkdir -p ~/.xtrkcad
    echo "xtrkcad_init: $(date)" > ~/.xtrkcad/startup.log
}

#####################################################################
#   S T A R T   O P E N B O X
#####################################################################
start_openbox() {
    echo "$ME: start openbox"
    #echo "sleeping for debug"
    #sleep 3600
    openbox-session &
    xtrkcad
}

#####################################################################
#   S T A R T   X T R K C A D   C O N T A I N E R
#####################################################################
startxtrkcad_container() {
    echo "$ME: run xtrkcad container"
    mkdir -p $XTRKCAD_DATADIR
    nohup x11docker --home=$XTRKCAD_DATADIR --xephyr --user=$DOCKER_USER --desktop --size=1920x1280 --name=xtrkcad xtrkcad:${XTRK_VER} /startxtrkcad.sh >/dev/null 2>&1 &
    echo "log at ~/.cache/x11docker/x11docker.log when session over"
    echo "your xtrkcad files (settings, track plans, etc.) in $XTRKCAD_DATADIR"
}

#####################################################################
#   V N C   P A S S W O R D
#####################################################################
vnc_password() {
    mkdir -p ~/.vnc
    x11vnc -storepasswd x11docker ~/.vnc/passwd
}

#####################################################################
#   M A I N
#####################################################################
if running_in_docker; then
    xtrkcad_init
    start_openbox
else
    startxtrkcad_container
fi
