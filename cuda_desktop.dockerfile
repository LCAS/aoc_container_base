ARG BASE_IMAGE=lcas.lincoln.ac.uk/ros_cuda:humble-main

FROM ${BASE_IMAGE} AS base

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    ros-${ROS_DISTRO}-desktop \
    && sudo rm -rf /var/lib/apt/lists/*
