FROM x11docker/xserver

ARG XTRK_VER=5.3.0
ARG XTRK_REL=GA-1
ARG XTRK_ARCH=x86_64
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000
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
    && apt-get -y install menu python3-xdg \
    && apt-get -y install fluxbox \
    && apt-get -y install firefox-esr \
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
    && echo "${DOCKER_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${DOCKER_USER} \
    && true

# vnc and cleanup
RUN \
    apt-get -y install x11vnc xvfb net-tools \
    && /apt_cleanup \
    && true

COPY --chown=${DOCKER_UID}:${DOCKER_GID} startxtrkcad.sh .

USER ${DOCKER_USER}
ENV HOME=/home/${DOCKER_USER}

CMD [ "/bin/bash", "-c", "/startxtrkcad.sh" ]
