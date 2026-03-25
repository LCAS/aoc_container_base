ARG BASE_IMAGE=ros:humble
ARG ROS_DISTRO=humble

FROM ${BASE_IMAGE} AS base
ARG BASE_IMAGE
ARG ROS_DISTRO

ENV BASE_IMAGE=${BASE_IMAGE}
ENV ROS_DISTRO=${ROS_DISTRO}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        gnupg \
        cmake \
        git \
        curl \
        wget \
        unzip \
        nano \
        ros-${ROS_DISTRO}-ros-base \
        ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
        python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8

RUN . /opt/ros/${ROS_DISTRO}/setup.sh && rosdep update --rosdistro ${ROS_DISTRO}

# Setup VirtualGL
RUN wget -q -O- https://packagecloud.io/dcommander/virtualgl/gpgkey | gpg --dearmor >/etc/apt/trusted.gpg.d/VirtualGL.gpg \
    && echo "deb [signed-by=/etc/apt/trusted.gpg.d/VirtualGL.gpg] https://packagecloud.io/dcommander/virtualgl/any/ any main" >>/etc/apt/sources.list.d/virtualgl.list \
    && apt-get update && apt-get install -y virtualgl libgl1 && rm -rf /var/lib/apt/lists/*

# Configure bash profile
RUN echo "if [ -f /etc/bash.bashrc ]; then source /etc/bash.bashrc; fi" >> /root/.bashrc && \
    echo 'PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /etc/bash.bashrc && \
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /etc/bash.bashrc

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ENV TVNC_VGL=1
ENV VGL_ISACTIVE=1
ENV VGL_FPS=25
ENV VGL_COMPRESS=0
ENV VGL_DISPLAY=egl
ENV VGL_WM=1
ENV VGL_PROBEGLX=0
ENV LD_PRELOAD=/usr/lib/libdlfaker.so:/usr/lib/libvglfaker.so
ENV SHELL=/bin/bash

CMD ["bash", "-l"]
