#!/bin/bash
# nvim-container.sh

CONTAINER_USER=$(id -un 2>/dev/null || echo "dev")
TARGET=$(realpath "${1:-.}")  # resolve to absolute path, default to current dir
TARGET_DIR=$(basename "${TARGET}")  # directory name used as the mount point inside the container
SCRIPT_DIR="$(dirname "$(realpath "$0")")" # realpath on $0 resolves this script's actual location regardless of where you call it from
CONTAINER_NAME="nvim-cont"

NVIM_VERSION=0.12.0
LAZYGIT_VERSION=0.60.0
TREE_SITTER_VERSION=0.26.8
FD_VERSION=10.4.2

CONTAINERFILE_HASH=$(printf '%s %s %s %s %s %s' \
  "$(sha256sum "${SCRIPT_DIR}/Containerfile" | cut -d' ' -f1)" \
  "$(sha256sum "${SCRIPT_DIR}/entrypoint.sh" | cut -d' ' -f1)" \
  "${NVIM_VERSION}" "${LAZYGIT_VERSION}" "${TREE_SITTER_VERSION}" "${FD_VERSION}" \
  | sha256sum | cut -d' ' -f1)
CURRENT_HASH=$(podman image inspect ${CONTAINER_NAME} --format '{{index .Labels "containerfile-hash"}}' 2>/dev/null)

if [ "${CURRENT_HASH}" != "${CONTAINERFILE_HASH}" ]; then
  echo "Image '${CONTAINER_NAME}' not found or Containerfile changed, building..."

  # Pre-download release archives on the host to avoid SSL issues inside the container build network.
  # Files are saved to downloads/ with fixed names; a .version sidecar tracks the expected version
  # so files are re-downloaded automatically when the version variables change.
  DOWNLOADS_DIR="${SCRIPT_DIR}/downloads"
  mkdir -p "${DOWNLOADS_DIR}"

  download_if_needed() {
    local url="$1"
    local dest="$2"
    local version="$3"
    local version_file="${dest}.version"
    if [ ! -f "${dest}" ] || [ "$(cat "${version_file}" 2>/dev/null)" != "${version}" ]; then
      echo "Downloading $(basename "${dest}")..."
      curl -L --http1.1 --retry 3 --retry-delay 5 --retry-all-errors --max-time 60 -o "${dest}" "${url}" || {
        rm -f "${dest}"
        echo "Error: failed to download $(basename "${dest}")"
        exit 1
      }
      echo "${version}" > "${version_file}"
    fi
  }

  download_if_needed \
    "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
    "${DOWNLOADS_DIR}/nvim-linux-x86_64.tar.gz" \
    "${NVIM_VERSION}"

  download_if_needed \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" \
    "${DOWNLOADS_DIR}/lazygit.tar.gz" \
    "${LAZYGIT_VERSION}"

  download_if_needed \
    "https://github.com/tree-sitter/tree-sitter/releases/download/v${TREE_SITTER_VERSION}/tree-sitter-cli-linux-x64.zip" \
    "${DOWNLOADS_DIR}/tree-sitter-cli-linux-x64.zip" \
    "${TREE_SITTER_VERSION}"

  download_if_needed \
    "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    "${DOWNLOADS_DIR}/fd.tar.gz" \
    "${FD_VERSION}"

  podman build -t ${CONTAINER_NAME} \
    --label "containerfile-hash=${CONTAINERFILE_HASH}" \
    --build-arg USERNAME=${CONTAINER_USER} \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    "${SCRIPT_DIR}"
fi

# Mount host git config into the container so git operations (e.g. commits via a neovim plugin) use the host user's identity and settings.
# Git config can live in two places: ~/.gitconfig (legacy) or ~/.config/git/config (XDG). We check both and mount whichever exist.
# The mounts are read-only (:ro) to prevent the container from modifying host config files.
# The conditional [ -f ... ] check is necessary because mounting a non-existent file path causes Podman to create a directory there instead.
GIT_CONFIG_MOUNTS=()
[ -f "${HOME}/.gitconfig" ] && GIT_CONFIG_MOUNTS+=(-v "${HOME}/.gitconfig:/home/${CONTAINER_USER}/.gitconfig:ro,z")
[ -f "${HOME}/.config/git/config" ] && GIT_CONFIG_MOUNTS+=(-v "${HOME}/.config/git/config:/home/${CONTAINER_USER}/.config/git/config:ro,z")

# --userns=keep-id ensures the in-container user owns the mounted files, Podman-specific - doesn't exist in Docker 
# :z on volume mounts tells Podman to relabel the files for SELinux, :z (lowercase) if you want the label shared across multiple containers, :Z (uppercase) for private to this container
podman run --rm -it \
  --userns=keep-id \
  --hostname "${CONTAINER_NAME}" \
  -v "${TARGET}:/home/${CONTAINER_USER}/${TARGET_DIR}:z" \
  -v "${SCRIPT_DIR}/config:/home/${CONTAINER_USER}/.config/nvim:z" \
  "${GIT_CONFIG_MOUNTS[@]}" \
  -e TERM=xterm-256color \
  -e COLORTERM=truecolor \
  -w "/home/${CONTAINER_USER}/${TARGET_DIR}" \
  ${CONTAINER_NAME} \
  /home/${CONTAINER_USER}/${TARGET_DIR}

