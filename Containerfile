FROM docker.io/ubuntu:24.04

ARG NVIM_VERSION=0.12.0
ARG LAZYGIT_VERSION=0.60.0
ARG TREE_SITTER_VERSION=0.26.8
ARG FD_VERSION=10.4.2

RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        build-essential \
        unzip \
        fzf \
        ripgrep \
    && curl -LO "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
    && tar -C /usr/local -xzf nvim-linux-x86_64.tar.gz --strip-components=1 \
    && rm nvim-linux-x86_64.tar.gz \
    && curl -LO "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" \
    && tar -C /usr/local/bin -xzf lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz lazygit \
    && rm lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz \
    && curl -LO "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-cli-linux-x64.zip" \
    && unzip tree-sitter-cli-linux-x64.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/tree-sitter \
    && rm tree-sitter-cli-linux-x64.zip \
    && curl -LO "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && tar -C /usr/local/bin -xzf fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz --strip-components=1 --wildcards '*/fd' \
    && rm fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz \
    && rm -rf /var/lib/apt/lists/*

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

# Entry point runs nvim with any arguments passed to the container through bash,
# so that it drops into a bash shell when you exit neovim
ENTRYPOINT ["bash", "-c", "nvim \"$@\"; exec bash", "--"]
