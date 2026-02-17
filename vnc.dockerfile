ARG BASE_IMAGE=debian:trixie-slim
FROM ${BASE_IMAGE} AS base

ARG BASE_IMAGE
ARG username=aoc
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
    nano \
    sudo \
    python3-setuptools \
    wget \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libxext6 \
    libx11-6 \
    x11-utils \
    python3-minimal \
    python3-pip \
    python3-numpy \
    python3-venv \
    less \
    tmux \
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
ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive
RUN curl -L -O https://github.com/VirtualGL/virtualgl/releases/download/3.1.1/virtualgl_3.1.1_${TARGETARCH}.deb && \
    apt-get update && \
    apt-get -y install ./virtualgl_3.1.1_${TARGETARCH}.deb && \
    rm virtualgl_3.1.1_${TARGETARCH}.deb && rm -rf /var/lib/apt/lists/* 
RUN curl -L -O https://github.com/TurboVNC/turbovnc/releases/download/3.1.1/turbovnc_3.1.1_${TARGETARCH}.deb && \
    apt-get update && \
    apt-get -y install ./turbovnc_3.1.1_${TARGETARCH}.deb && \
    rm turbovnc_3.1.1_${TARGETARCH}.deb && rm -rf /var/lib/apt/lists/* 
RUN addgroup --system vglusers && adduser ${username} vglusers


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

RUN cat <<EOF > /usr/share/glvnd/egl_vendor.d/10_nvidia.json
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libEGL_nvidia.so.0"
    }
}
EOF

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

# thunar 

COPY docker/vnc-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

# Set default XFCE wallpaper -- doesnt work
# COPY aoc_wallpaper.jpg /usr/share/backgrounds/xfce/aoc_wallpaper.jpg
# RUN mkdir -p /home/${username}/.config/xfce4/xfconf/xfce-perchannel-xml && \
#     cat > /home/${username}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
# <?xml version="1.0" encoding="UTF-8"?>
# <channel name="xfce4-desktop" version="1.0">
#   <property name="backdrop" type="empty">
#     <property name="screen0" type="empty">
#       <property name="monitor0" type="empty">
#         <property name="image-path" type="string" value="/usr/share/backgrounds/xfce/aoc_wallpaper.jpg"/>
#                 <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/aoc_wallpaper.jpg"/>
#         <property name="image-show" type="bool" value="true"/>
#                 <property name="workspace0" type="empty">
#                     <property name="last-image" type="string" value="/usr/share/backgrounds/xfce/aoc_wallpaper.jpg"/>
#                 </property>
#       </property>
#     </property>
#   </property>
# </channel>
# EOF
RUN chown -R ${username}:${username} /home/${username}/.config

# Allow other containers to share windows into this display
RUN echo 'xhost +local: 2>/dev/null' >> ~/.bashrc

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