#!/bin/bash
# nvim-container.sh

CONTAINER_USER=$(id -un 2>/dev/null || echo "dev")
TARGET=$(realpath "${1:-.}")  # resolve to absolute path, default to current dir
TARGET_DIR=$(basename "${TARGET}")  # directory name used as the mount point inside the container
SCRIPT_DIR="$(dirname "$(realpath "$0")")" # realpath on $0 resolves this script's actual location regardless of where you call it from
IMAGE_NAME="nvim-cont"

NVIM_VERSION=0.12.0

CONTAINERFILE_HASH=$(printf '%s %s %s %s %s %s' \
  "$(sha256sum "${SCRIPT_DIR}/Containerfile" | cut -d' ' -f1)" \
  "$(sha256sum "${SCRIPT_DIR}/entrypoint.sh" | cut -d' ' -f1)" \
  "${NVIM_VERSION}" "${LAZYGIT_VERSION}" "${TREE_SITTER_VERSION}" "${FD_VERSION}" \
  | sha256sum | cut -d' ' -f1)
CURRENT_HASH=$(podman image inspect ${IMAGE_NAME} --format '{{index .Labels "containerfile-hash"}}' 2>/dev/null)

if [ "${CURRENT_HASH}" != "${CONTAINERFILE_HASH}" ]; then
  echo "Image '${IMAGE_NAME}' not found or Containerfile changed, building..."

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
      for attempt in 1 2 3; do
        curl -L --http1.1 --max-time 60 -o "${dest}" "${url}" && break
        [ $attempt -eq 3 ] && { rm -f "${dest}"; echo "Error: failed to download $(basename "${dest}")"; exit 1; }
        sleep 5
      done
      echo "${version}" > "${version_file}"
    fi
  }

  download_if_needed \
    "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
    "${DOWNLOADS_DIR}/nvim-linux-x86_64.tar.gz" \
    "${NVIM_VERSION}"

  podman build -t ${IMAGE_NAME} \
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

# Ensure that the required nvim directories exist on the host
mkdir -p "${HOME}/.local/share/${IMAGE_NAME}" "${HOME}/.local/state/${IMAGE_NAME}"

# --userns=keep-id ensures the in-container user owns the mounted files, Podman-specific - doesn't exist in Docker 
# :z on volume mounts tells Podman to relabel the files for SELinux, :z (lowercase) if you want the label shared across multiple containers, :Z (uppercase) for private to this container
podman run --rm -it \
  --userns=keep-id \
  --hostname "${IMAGE_NAME}" \
  -v "${TARGET}:/home/${CONTAINER_USER}/${TARGET_DIR}:z" \
  -v "${SCRIPT_DIR}/config/nvim:/home/${CONTAINER_USER}/.config/nvim:z" \
  -v "${SCRIPT_DIR}/config/tmux:/home/${CONTAINER_USER}/.config/tmux:z" \
  -v "${HOME}/.local/share/${IMAGE_NAME}:/home/${CONTAINER_USER}/.local/share/nvim:z" \
  -v "${HOME}/.local/state/${IMAGE_NAME}:/home/${CONTAINER_USER}/.local/state/nvim:z" \
  "${GIT_CONFIG_MOUNTS[@]}" \
  -e TERM=xterm-256color \
  -e COLORTERM=truecolor \
  -e LANG=C.UTF-8 \
  -w "/home/${CONTAINER_USER}/${TARGET_DIR}" \
  ${IMAGE_NAME} \
  /home/${CONTAINER_USER}/${TARGET_DIR}

