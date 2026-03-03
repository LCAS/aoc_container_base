ARG BASE_IMAGE=ros:humble
ARG ROS_DISTRO=humble

FROM ${BASE_IMAGE} AS base
ARG BASE_IMAGE
ARG ROS_DISTRO

ENV BASE_IMAGE=${BASE_IMAGE}
ENV ROS_DISTRO=${ROS_DISTRO}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential \
    ca-certificates \
    cmake \
    git \
    curl \
    wget \
    unzip \
    ros-${ROS_DISTRO}-ros-base \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*
    
RUN . /opt/ros/${ROS_DISTRO}/setup.sh && rosdep update

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

# Cyclone DDS
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    ros-${ROS_DISTRO}-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*
COPY cyclonedds.xml /etc/cyclonedds.xml 
  
# Configure bash profile
RUN echo "if [ -f /etc/bash.bashrc ]; then source /etc/bash.bashrc; fi" >> /root/.bashrc && \
    echo 'PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /etc/bash.bashrc && \
    echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> /etc/bash.bashrc && \
    echo "alias t='tmux'" >> /etc/bash.bashrc && \
    echo "alias cls='clear'" >> /etc/bash.bashrc && \
    echo "RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /etc/bash.bashrc && \
    echo "CYCLONEDDS_URI=file:///etc/cyclonedds.xml" >> /etc/bash.bashrc

USER ros
CMD ["bash", "-l"]

