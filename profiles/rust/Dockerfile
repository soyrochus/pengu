# syntax=docker/dockerfile:1
ARG RUST_BASE_IMAGE=rust:bookworm
FROM ${RUST_BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=pengu
ARG UID=1000
ARG GID=1000

# Base tools (keep consistent with default; add common Rust-native deps)
RUN apt-get update && apt-get install -y --no-install-recommends \
    imagemagick \
    curl wget git vim less unzip zip build-essential \
    pkg-config \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# (Optional but common) For crates that need TLS/openssl headers:
# RUN apt-get update && apt-get install -y --no-install-recommends libssl-dev && rm -rf /var/lib/apt/lists/*

# Create non-root user matching host UID/GID (same as your default)
RUN set -eux; \
    if getent passwd "${UID}" >/dev/null; then \
      existing_user="$(getent passwd "${UID}" | cut -d: -f1)"; \
      if [ "${existing_user}" != "${USERNAME}" ]; then \
        existing_group="$(id -gn "${existing_user}")"; \
        usermod -l "${USERNAME}" "${existing_user}"; \
        if [ "${existing_group}" != "${USERNAME}" ]; then \
          groupmod -n "${USERNAME}" "${existing_group}"; \
        fi; \
      fi; \
      current_home="$(getent passwd "${USERNAME}" | cut -d: -f6)"; \
      if [ "${current_home}" != "/home/${USERNAME}" ]; then \
        usermod -d "/home/${USERNAME}" -m "${USERNAME}"; \
      fi; \
    else \
      if getent group "${GID}" >/dev/null; then \
        existing_group="$(getent group "${GID}" | cut -d: -f1)"; \
        if [ "${existing_group}" != "${USERNAME}" ]; then \
          groupmod -n "${USERNAME}" "${existing_group}"; \
        fi; \
      else \
        groupadd -g "${GID}" "${USERNAME}"; \
      fi; \
      useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USERNAME}"; \
    fi; \
    if getent group "${USERNAME}" >/dev/null; then \
      usermod -g "${USERNAME}" "${USERNAME}"; \
    fi

WORKDIR /workspace
RUN chown -R ${UID}:${GID} /workspace
USER ${USERNAME}

# Rust official image already provides rustup/cargo; ensure user sees cargo bins if needed
ENV PATH="/home/${USERNAME}/.cargo/bin:/home/${USERNAME}/.local/bin:${PATH}"

# Keep Rust build artifacts out of /workspace to avoid host bind-mount permission quirks
ENV CARGO_TARGET_DIR="/home/pengu/.cargo/target"

CMD ["bash"]
