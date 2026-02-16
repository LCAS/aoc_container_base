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
    cmake \
    git \
    curl \
    wget \
    unzip \
    ros-${ROS_DISTRO}-ros-base \
    && rm -rf /var/lib/apt/lists/*

RUN . /opt/ros/${ROS_DISTRO}/setup.sh && rosdep update

