FROM docker.io/ubuntu:24.04 AS builder

ARG NVIM_VERSION=0.12.0

RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \ # TODO: add other dependencies needed by neovim plugins here
    && curl -LO "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
    && tar -C /usr/local -xzf nvim-linux-x86_64.tar.gz --strip-components=1 \
    && rm nvim-linux-x86_64.tar.gz \
    && rm -rf /var/lib/apt/lists/*

# Create a user whose UID/GID matches the host user, passed in at build time.
# This ensures --userns=keep-id maps correctly with no permission issues.
ARG USERNAME=dev # default username, can be overridden at build time with --build-arg USERNAME=<name>
ARG UID=1000 # this is default, but host user UID should be passed in at build time with --build-arg UID=$(id -u)
ARG GID=1000 # this is default, but host group GID should be passed in at build time with --build-arg GID=$(id -g)
RUN groupadd -g ${GID} --non-unique ${USERNAME} \
    && useradd -m -s /bin/bash -u ${UID} -g ${GID} --non-unique ${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Entry point runs nvim with any arguments passed to the container through bash,
# so that it drops into a bash shell when you exit neovim
ENTRYPOINT ["bash", "-c", "nvim \"$@\"; exec bash", "--"]