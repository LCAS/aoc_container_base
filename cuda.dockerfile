ARG BASE_IMAGE=nvidia/cuda:11.8.0-runtime-ubuntu22.04
ARG ROS_DISTRO=humble

###########################################
FROM ${BASE_IMAGE} AS base
ARG BASE_IMAGE
ARG ROS_DISTRO
 
ENV BASE_IMAGE=${BASE_IMAGE}
ENV ROS_DISTRO=${ROS_DISTRO}

ENV DEBIAN_FRONTEND=noninteractive

# Install language
RUN apt-get update ; \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  locales \
  curl \
  gnupg2 \
  lsb-release \
  git \
  nano \
  python3-setuptools \
  software-properties-common \
  wget \
  tzdata \
  && locale-gen en_US.UTF-8 \
  && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

# Prepare ROS2
RUN add-apt-repository universe \
  && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-ros-base \
    python3-rosdep \
    && rm -rf /var/lib/apt/lists/*

RUN . /opt/ros/${ROS_DISTRO}/setup.sh && rosdep init && rosdep update

ARG USERNAME=ros
ARG USER_UID=1001
ARG USER_GID=$USER_UID

# Create a non-root user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  # Add sudo support for the non-root user
  && apt-get update \
  && apt-get install -y --no-install-recommends sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && rm -rf /var/lib/apt/lists/*

# Configure bash profile
RUN echo "if [ -f /etc/bash.bashrc ]; then source /etc/bash.bashrc; fi" >> /root/.bashrc && \
    echo 'PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /etc/bash.bashrc && \
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /etc/bash.bashrc && \
    echo "alias t='tmux'" >> /etc/bash.bashrc && \
    echo "alias cls='clear'" >> /etc/bash.bashrc

CMD ["bash", "-l"]

