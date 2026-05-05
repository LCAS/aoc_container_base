ARG BASE_IMAGE=debian:trixie-slim
FROM ${BASE_IMAGE} AS base

ARG BASE_IMAGE
ARG username=lcas
ENV BASE_IMAGE=${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1

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
    wget \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libxext6 \
    libx11-6 \
    x11-utils \
    screen \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash -G video ${username}

# Fix /tmp/.X11-unix permissions
RUN mkdir -p /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix

# Install Python 3 for noVNC/websockify
RUN apt-get update && apt-get install -y python3 && rm -rf /var/lib/apt/lists/*

# Install TurboVNC
RUN wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/TurboVNC.gpg] https://packagecloud.io/dcommander/turbovnc/any/ any main" >>/etc/apt/sources.list.d/TurboVNC.list \
    && apt-get update && apt-get install -y turbovnc && rm -rf /var/lib/apt/lists/*

# Install noVNC
ENV NOVNC_VERSION=1.6.0
ENV WEBSOCKETIFY_VERSION=0.13.0
RUN mkdir -p /usr/local/novnc \
    && curl -sSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.zip -o /tmp/novnc-install.zip \
    && unzip /tmp/novnc-install.zip -d /usr/local/novnc \
    && cp /usr/local/novnc/noVNC-${NOVNC_VERSION}/vnc.html /usr/local/novnc/noVNC-${NOVNC_VERSION}/index.html \
    && curl -sSL https://github.com/novnc/websockify/archive/v${WEBSOCKETIFY_VERSION}.zip -o /tmp/websockify-install.zip \
    && unzip /tmp/websockify-install.zip -d /usr/local/novnc \
    && ln -s /usr/local/novnc/websockify-${WEBSOCKETIFY_VERSION} /usr/local/novnc/noVNC-${NOVNC_VERSION}/utils/websockify \
    && rm -f /tmp/websockify-install.zip /tmp/novnc-install.zip \
    && sed -i -E 's/^python /python3 /' /usr/local/novnc/websockify-${WEBSOCKETIFY_VERSION}/run

FROM base AS xfce

# Install XFCE4
RUN apt-get update \
    && apt-get -y install \
        xfce4-session \
        xfce4-panel \
        xfdesktop4 \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get purge -y xfce4-screensaver

COPY vnc-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

COPY vnc-healthcheck.sh /vnc-healthcheck.sh
RUN chmod +x /vnc-healthcheck.sh
# start_period allows the VNC stack time to fully initialize before health checks start counting failures
HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=5 \
    CMD ["/vnc-healthcheck.sh"]

# Copy in wallpaper
COPY ./wallpapers/*.jpg /usr/share/backgrounds/xfce/

# Allow other containers to share windows into this display
RUN echo 'xhost +local: 2>/dev/null' >> /etc/bash.bashrc && \
    echo "if [ -f /etc/bash.bashrc ]; then source /etc/bash.bashrc; fi" >> /root/.bashrc

EXPOSE 5801

USER ${username}
ENV HOME=/home/${username}
WORKDIR ${HOME}
RUN mkdir -p ${HOME}/.local/bin

ENV DISPLAY=:1
ENV TVNC_VGL=1
ENV SHELL=/bin/bash

CMD ["sleep", "infinity"]
