# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=pengu
ARG UID=1000
ARG GID=1000

# Base tools + ImageMagick
RUN apt-get update && apt-get install -y --no-install-recommends \
    imagemagick \
    curl wget git vim less unzip zip build-essential \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user matching host UID/GID (avoids root-owned files on bind mounts)
RUN groupadd -g ${GID} ${USERNAME} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USERNAME}

WORKDIR /workspace
RUN chown -R ${USERNAME}:${USERNAME} /workspace
USER ${USERNAME}

ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# Default: do nothing until you exec/shell in
CMD ["bash"]
