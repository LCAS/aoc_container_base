ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS base
ARG username=lcas

ARG DOCKER_GID=984

# Install Docker (for docker exec etc)
USER root
RUN apt-get update && \
    apt-get install -y ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli konsole && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g $DOCKER_GID docker && \
    usermod -aG docker ${username}

USER ${username}
