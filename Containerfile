FROM docker.io/ubuntu:24.04

RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        tmux \
        ncurses-term \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY downloads/nvim-linux-x86_64.tar.gz /tmp/
RUN tar -C /usr/local -xzf /tmp/nvim-linux-x86_64.tar.gz --strip-components=1 \
    && rm /tmp/nvim-linux-x86_64.tar.gz

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create a user whose UID/GID matches the host user, passed in at build time.
# This ensures --userns=keep-id maps correctly with no permission issues.
# Username should be passed in at build time with --build-arg USERNAME=<name>
# Host user UID should be passed in at build time with --build-arg UID=$(id -u)
# Host group GID should be passed in at build time with --build-arg GID=$(id -g)
ARG USERNAME=dev 
ARG UID=1000 
ARG GID=1000 
RUN groupadd -g ${GID} --non-unique ${USERNAME} \
    && useradd -m -s /bin/bash -u ${UID} -g ${GID} --non-unique ${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}
# home directory. HOME must be set explicitly because USER does not update it.
ENV HOME=/home/${USERNAME}

# Install OpenCode CLI as the container user, not root
ARG OPENCODE_VERSION=1.14.19
RUN curl -fsSL https://opencode.ai/install | bash -s -- --version ${OPENCODE_VERSION}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
