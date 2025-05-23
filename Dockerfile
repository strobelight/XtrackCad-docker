FROM x11docker/xserver

ARG XTRK_VER=5.3.0
ARG XTRK_REL=GA-1
ARG XTRK_ARCH=x86_64
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000
ARG DOCKER_AUDIO_GID=996
# must pass a build arg value
ARG DOCKER_USER

ENV DEBIAN_FRONTEND=noninteractive

# xpra patches
RUN \
    apt-get update || true \
    && apt-get -y install wget \
    && apt-get -y install ca-certificates \
    && wget -O /usr/share/keyrings/xpra.asc https://xpra.org/xpra.asc \
    && chmod 644 /usr/share/keyrings/xpra.asc \
    && wget -O /etc/apt/sources.list.d/xpra.sources https://raw.githubusercontent.com/Xpra-org/xpra/refs/heads/master/packaging/repos/bullseye/xpra.sources \
    && rm -f /etc/apt/sources.list.d/xpra.list /xpra-gpg.asc /nxagent*deb \
    && true

# base system
RUN \
    apt-get update \
    && apt-get -y install wget sudo file less \
    && apt-get -qqy install xorg x11-apps \
    && apt-get -y install menu python3-xdg python3-netifaces python3-cups python3-dbus \
    && apt-get -y install fluxbox \
    && apt-get -y install firefox-esr \
    && apt-get -y install rox-filer \
    && apt-get -y install libcups2 \
    && apt-get -y install alsa-utils \
    && apt-get -y install libpulse0 \
    && apt-get -y install xpra \
    && true

# xtrkcad
RUN \
    wget https://sourceforge.net/projects/xtrkcad-fork/files/XTrackCad/Version%20${XTRK_VER}/xtrkcad-setup-${XTRK_VER}${XTRK_REL}.${XTRK_ARCH}.deb \
    && apt -y install ./xtrkcad-setup-${XTRK_VER}${XTRK_REL}.${XTRK_ARCH}.deb \
    && rm -f ./xtrkcad-setup-${XTRK_VER}${XTRK_REL}.${XTRK_ARCH}.deb \
    && true

# user
RUN \
    userdel -f ubuntu || true \
    && useradd -m -u ${DOCKER_UID} ${DOCKER_USER} 2>&1 \
    && groupmod --gid ${DOCKER_AUDIO_GID} audio \
    && usermod -aG audio ${DOCKER_USER} \
    && usermod -aG xpra ${DOCKER_USER} \
    && mkdir -p /run/user/${DOCKER_UID} \
    && chown ${DOCKER_UID}:${DOCKER_GID} /run/user/${DOCKER_UID} \
    && chmod 1777 /run/user/${DOCKER_UID} \
    && mkdir -p /run/xpra \
    && chown root:xpra /run/xpra \
    && chmod 1775 /run/xpra \
    && echo "${DOCKER_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${DOCKER_USER} \
    && true

# vnc and cleanup
RUN \
    apt-get -y install x11vnc xvfb net-tools \
    && /apt_cleanup \
    && true

COPY --chown=${DOCKER_UID}:${DOCKER_GID} startxtrkcad.sh .
COPY --chown=${DOCKER_UID}:${DOCKER_GID} fluxbox fluxbox/
COPY --chown=${DOCKER_UID}:${DOCKER_GID} rox-filer.config .

USER ${DOCKER_USER}
ENV HOME=/home/${DOCKER_USER}

CMD [ "/bin/bash", "-c", "/startxtrkcad.sh" ]
