ARG BASE_IMAGE=ros:humble
FROM ${BASE_IMAGE} AS base

ENV BASE_IMAGE=${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    unzip

RUN rosdep init && rosdep update