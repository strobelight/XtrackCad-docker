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
    echo "$ME: Executing in container, start openbox and xtrkcad"
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
    if [ "$1" = "-v" ]; then
        X11DEBUG="-V --keepcache"
    else
        X11DEBUG=""
    fi
    # --keepcache excludes --rm so need to remove any exited containers
    docker rm xtrkcad >/dev/null 2>&1
    #echo "nohup x11docker $X11DEBUG --home=$XTRKCAD_DATADIR --xephyr --user=$DOCKER_USER --desktop --size=1920x1280 --name=xtrkcad xtrkcad:${XTRK_VER} /startxtrkcad.sh  >/dev/null 2>&1 &"
    nohup x11docker $X11DEBUG --home=$XTRKCAD_DATADIR --xephyr --user=$DOCKER_USER --desktop --size=1920x1280 --name=xtrkcad xtrkcad:${XTRK_VER} /startxtrkcad.sh  >/dev/null 2>&1 &
    echo "log at ~/.cache/x11docker/x11docker.log when session over"
    echo "your xtrkcad files (settings, track plans, etc.) in $XTRKCAD_DATADIR"
}

#####################################################################
#   F I R S T   T I M E   O N   H O S T
#####################################################################
xtrkcad_hostinit() {
    [[ -f ~/.local/share/applications/xtrkcad.desktop ]] && return
    [[ -f ~/.local/bin/xtrkcad  ]] && return
    echo SETUP ICONS
    # Set icon for file browser
    xdg-icon-resource install --context mimetypes --novendor --size 64 xtrkcad.png xtrkcad
    # set icon for file browser
    xdg-icon-resource install --context apps --novendor --size 64 xtrkcad.png xtrkcad
    xdg-icon-resource install --context apps --novendor --size 64 xtrkcad.png application-x-xtrkcad
    echo SETUP MIME
    # mimetype for .xtc files is application/x-xtrkcad
    xdg-mime install --novendor xtrkcad.xml
    # default handler for application/x-xtrkcad is xtrkcad
    xdg-mime default xtrkcad.desktop application/x-xtrkcad
    echo SETUP DESKTOP
    # add app to system menu
    xdg-desktop-menu install --novendor xtrkcad.desktop
    # add desktop shortcut
    xdg-desktop-icon install --novendor xtrkcad.desktop
    chmod 755 ${HOME}/Desktop/xtrkcad.desktop
    # add link to script
    ln -s $(pwd)/startxtrkcad.sh ~/.local/bin/xtrkcad
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
    xtrkcad_hostinit
    startxtrkcad_container $*
fi
