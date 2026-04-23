FROM docker.io/ubuntu:24.04

RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gcc \
        git \
        less \
        make \
        tmux \
        ncurses-term \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY downloads/nvim-linux-x86_64.tar.gz /tmp/
RUN tar -C /usr/local -xzf /tmp/nvim-linux-x86_64.tar.gz --strip-components=1 \
    && rm /tmp/nvim-linux-x86_64.tar.gz

COPY downloads/lazygit.tar.gz /tmp/
RUN tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit \
    && rm /tmp/lazygit.tar.gz

COPY downloads/delta.tar.gz /tmp/
RUN tar -C /usr/local/bin -xzf /tmp/delta.tar.gz --strip-components=1 \
    --wildcards '*/delta' \
    && rm /tmp/delta.tar.gz

COPY downloads/opencode.tar.gz /tmp/
RUN tar -C /usr/local/bin -xzf /tmp/opencode.tar.gz opencode \
    && rm /tmp/opencode.tar.gz

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

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
