FROM docker.io/ubuntu:24.04

# ── System Dependencies ──
# Package purposes (documented in AGENTS.md):
# - curl: installed for general purpose uses
# - ca-certificates: required to connect to LLM providers on private networks
# - fd, fzf: required for fzf-lua plugin
# - gcc, make: Tree-sitter parser compilation (nvim-treesitter)
# - less: required by Delta
# - tmux: Tmux-tabs entrypoint and session management
# - ncurses-term: Extended terminfo definitions for OpenCode TUI rendering (added with OpenCode CLI in commit cc6abe54)
# - openssh-client: SSH operations (git over SSH, known_hosts updates)
# - ripgrep: installed for general purpose uses, and also used by several Neovim plugins for searching within files
# - unzip: required to extract tree-sitter
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gcc \
        git \
        fzf \
        less \
        make \
        tmux \
        ncurses-term \
        openssh-client \
        ripgrep \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# ── Delta Installation ──
COPY downloads/delta.tar.gz /tmp/
RUN tar -C /usr/local/bin -xzf /tmp/delta.tar.gz --strip-components=1 \
    --wildcards '*/delta' \
    && rm /tmp/delta.tar.gz

# ── fd Installation ──
COPY downloads/fd.tar.gz /tmp/
RUN tar -C /usr/local/bin -xzf /tmp/fd.tar.gz --strip-components=1 --wildcards '*/fd' \
    && rm /tmp/fd.tar.gz

# ── Lazygit Installation ──
COPY downloads/lazygit.tar.gz /tmp/
RUN tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit \
    && rm /tmp/lazygit.tar.gz

# ── Neovim Installation ──
COPY downloads/nvim-linux-x86_64.tar.gz /tmp/
RUN tar -C /usr/local -xzf /tmp/nvim-linux-x86_64.tar.gz --strip-components=1 \
    && rm /tmp/nvim-linux-x86_64.tar.gz

# ── OpenCode Installation ──
COPY downloads/opencode.tar.gz /tmp/
RUN tar -C /usr/local/bin -xzf /tmp/opencode.tar.gz opencode \
    && rm /tmp/opencode.tar.gz

# ── Treesitter Installation ──
COPY downloads/tree-sitter-cli-linux-x64.zip /tmp/
RUN unzip /tmp/tree-sitter-cli-linux-x64.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/tree-sitter \
    && rm /tmp/tree-sitter-cli-linux-x64.zip

# ── Entrypoint Setup ──
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ── Runtime User Configuration ──
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
