ARG BASE_IMAGE=debian:trixie-slim
FROM ${BASE_IMAGE} AS base

ARG BASE_IMAGE
ARG username=lcas
ENV BASE_IMAGE=${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    VNC_PORT=5900 \
    NOVNC_PORT=5801 \
    RESOLUTION=1366x768x24

# Install timezone
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg2 \
    lsb-release \
    sudo \
    wget \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libxext6 \
    libx11-6 \
    x11-utils \
    less \
    screen \
    unzip \
    x11-apps \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash -G video,sudo ${username} && \
    echo "${username} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Fix /tmp/.X11-unix permissions
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix

# Install VirtualGL
RUN wget -q -O- https://packagecloud.io/dcommander/virtualgl/gpgkey | gpg --dearmor >/etc/apt/trusted.gpg.d/VirtualGL.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/VirtualGL.gpg] https://packagecloud.io/dcommander/virtualgl/any/ any main" >> /etc/apt/sources.list.d/virtualgl.list && \
    apt update && apt install -y virtualgl libgl1 && rm -rf /var/lib/apt/lists/*

RUN cat <<EOF > /usr/share/glvnd/egl_vendor.d/10_nvidia.json
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libEGL_nvidia.so.0"
    }
}
EOF

# Install TurboVNC
RUN wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/TurboVNC.gpg] https://packagecloud.io/dcommander/turbovnc/any/ any main" >> /etc/apt/sources.list.d/TurboVNC.list && \
    apt update && apt install -y turbovnc && rm -rf /var/lib/apt/lists/*

# Install noVNC
ENV NOVNC_VERSION=1.4.0
ENV WEBSOCKETIFY_VERSION=0.10.0
RUN mkdir -p /usr/local/novnc && \
    curl -sSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.zip -o /tmp/novnc-install.zip && \
    unzip /tmp/novnc-install.zip -d /usr/local/novnc && \
    cp /usr/local/novnc/noVNC-${NOVNC_VERSION}/vnc.html /usr/local/novnc/noVNC-${NOVNC_VERSION}/index.html && \
    curl -sSL https://github.com/novnc/websockify/archive/v${WEBSOCKETIFY_VERSION}.zip -o /tmp/websockify-install.zip && \
    unzip /tmp/websockify-install.zip -d /usr/local/novnc && \
    ln -s /usr/local/novnc/websockify-${WEBSOCKETIFY_VERSION} /usr/local/novnc/noVNC-${NOVNC_VERSION}/utils/websockify && \
    rm -f /tmp/websockify-install.zip /tmp/novnc-install.zip && \
    sed -i -E 's/^python /python3 /' /usr/local/novnc/websockify-${WEBSOCKETIFY_VERSION}/run

FROM base AS xfce

# Install XFCE4
RUN apt-get update && \
    apt-get -y install \
    xfce4-session \
    xfce4-panel \
    xfdesktop4 \
    konsole \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get purge -y xfce4-screensaver

COPY docker/vnc-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

# Set default XFCE wallpaper -- doesnt work
# COPY aoc_wallpaper.jpg /usr/share/backgrounds/xfce/aoc_wallpaper.jpg

# Allow other containers to share windows into this display
RUN echo 'xhost +local: 2>/dev/null' >> ~/.bashrc && \
    echo "if [ -f /etc/bash.bashrc ]; then source /etc/bash.bashrc; fi" >> /root/.bashrc && \
    echo "alias cls='clear'" >> /etc/bash.bashrc && \
    echo 'echo -e "$(printf "%80s" | tr " " "-") \nYou are inside the VNC container,\n - You do not have access to ROS in this terminal\n - You may docker exec into other containers.\n$(printf "%80s" | tr " " "-")\n"' >> /etc/bash.bashrc

EXPOSE 5801

USER ${username}
ENV HOME=/home/${username}
WORKDIR ${HOME}
RUN mkdir -p ${HOME}/.local/bin 

ENV DISPLAY=:1
ENV TVNC_VGL=1
ENV VGL_ISACTIVE=1
ENV VGL_FPS=25
ENV VGL_COMPRESS=0
ENV VGL_DISPLAY=egl
ENV VGL_WM=1
ENV VGL_PROBEGLX=0
ENV LD_PRELOAD=/usr/lib/libdlfaker.so:/usr/lib/libvglfaker.so
ENV SHELL=/bin/bash

FROM xfce AS docker-tools

ARG DOCKER_GID=984

# Install Docker (for docker exec etc)
USER root
RUN apt-get update && \
    apt-get install -y ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g $DOCKER_GID docker && \
    usermod -aG docker ${username}

USER ${username}
