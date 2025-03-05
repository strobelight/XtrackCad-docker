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

# do some logging
export LOGFILE=/tmp/startxtrkcad.log
exec > >(tee $LOGFILE)
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
    #echo "xtrkcad_init: $(date)" > ~/.xtrkcad/startup.log
}

#####################################################################
#   S T A R T   S E S S I O N
#####################################################################
start_session() {
    echo "$ME: Executing in container, start window mgr and xtrkcad"
    #echo "sleeping for debug"
    #sleep 3600
    cd $HOME
    if [ ! -d .fluxbox ]; then
        mkdir .fluxbox
        cp /fluxbox/* .fluxbox
    fi
    if [ ! -d .config/rox.sourceforge.net ]; then
        mkdir -p .config/rox.sourceforge.net
        cp -r /rox.sourceforge.net .config
    fi
    if [ ! -L xtrkcad ]; then
        ln -s /usr/share/xtrkcad xtrkcad
    fi
    if [ ! -L examples ]; then
        ln -s /usr/share/xtrkcad/examples examples
    fi
    startfluxbox &
    LOG_ALLMODULES=" \
        -d Bezier=1 \
        -d block=1 \
        -d carDlgList=1 \
        -d carDlgState=1 \
        -d carInvList=1 \
        -d carList=1 \
        -d command=1 \
        -d control=1 \
        -d Cornu=1 \
        -d cornuturnoutdesigner=1 \
        -d curve=1 \
        -d curveSegs=1 \
        -d dumpElev=1 \
        -d ease=1 \
        -d endPt=1 \
        -d group=1 \
        -d init=1 \
        -d join=1 \
        -d locale=1 \
        -d malloc=0 \
        -d mapsize=1 \
        -d modify=1 \
        -d mouse=0 \
        -d pan=1 \
        -d paraminput=1 \
        -d paramlayout=1 \
        -d params=1 \
        -d paramupdate=1 \
        -d playbackcursor=1 \
        -d print=1 \
        -d profile=1 \
        -d readTracks=1 \
        -d redraw=1 \
        -d regression=1 \
        -d scale=1 \
        -d sensor=1 \
        -d shortPath=1 \
        -d signal=1 \
        -d splitturnout=1 \
        -d Structure=1 \
        -d suppresscheckpaths=1 \
        -d switchmotor=1 \
        -d timedrawgrid=1 \
        -d timedrawtracks=1 \
        -d timemainredraw=1 \
        -d timereadfile=1 \
        -d track=1 \
        -d trainMove=1 \
        -d trainPlayback=1 \
        -d traverseBezier=1 \
        -d traverseBezierSegs=1 \
        -d traverseCornu=1 \
        -d traverseJoint=1 \
        -d traverseTurnout=1 \
        -d turnout=1 \
        -d undo=1 \
        -d zoom=1 \
    "
    LOGFILE=".xtrkcad/xtrkcad.$(date '+%a%H').log"
    rm -f ${LOGFILE}.bak
    mv ${LOGFILE} ${LOGFILE}.bak 2>/dev/null
    rm -f ${LOGFILE}
    xtrkcad -v -l $LOGFILE $LOG_ALLMODULES $1
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
    echo "nohup x11docker $X11DEBUG --printer --pulseaudio=host --network --home=$XTRKCAD_DATADIR --xephyr --user=$DOCKER_USER --desktop --size=1920x1280 xtrkcad:${XTRK_VER} /startxtrkcad.sh $* >/dev/null 2>&1 &"
    nohup x11docker $X11DEBUG --printer --pulseaudio=host --network --home=$XTRKCAD_DATADIR --xephyr --user=$DOCKER_USER --desktop --size=1920x1280 xtrkcad:${XTRK_VER} /startxtrkcad.sh $* >/dev/null 2>&1 &
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
    start_session $*
else
    xtrkcad_hostinit
    XTRK_FILE=$(basename $1 2>/dev/null)
    # uncomment for debug only to start container with clean slate (removes track plans!)
    #rm -rf $XTRKCAD_DATADIR
    startxtrkcad_container $XTRK_FILE
fi
