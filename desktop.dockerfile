ARG BASE_IMAGE=lcas.lincoln.ac.uk/ros_cuda:humble-main
ARG ROS_DISTRO=humble

FROM ${BASE_IMAGE} AS base
ARG ROS_DISTRO

RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-desktop \
    && rm -rf /var/lib/apt/lists/*