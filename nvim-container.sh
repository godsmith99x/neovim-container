#!/bin/bash
# nvim-container.sh

CONTAINER_USER=$(id -un 2>/dev/null || echo "dev")
TARGET=$(realpath "${1:-.}")  # resolve to absolute path, default to current dir
TARGET_DIR=$(basename "${TARGET}")  # directory name used as the mount point inside the container
SCRIPT_DIR="$(dirname "$(realpath "$0")")" # realpath on $0 resolves this script's actual location regardless of where you call it from
CONTAINER_NAME="nvim-cont"

CONTAINERFILE_HASH=$(sha256sum "${SCRIPT_DIR}/Containerfile" | cut -d' ' -f1)
CURRENT_HASH=$(podman image inspect ${CONTAINER_NAME} --format '{{index .Labels "containerfile-hash"}}' 2>/dev/null)

if [ "${CURRENT_HASH}" != "${CONTAINERFILE_HASH}" ]; then
  echo "Image '${CONTAINER_NAME}' not found or Containerfile changed, building..."
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

# --userns=keep-id ensures the in-container user owns the mounted files, Podman-specific - doesn't exist in Docker 
# :z on volume mounts tells Podman to relabel the files for SELinux, :z (lowercase) if you want the label shared across multiple containers, :Z (uppercase) for private to this container
# "$@" passes all arguments given to this script into the container so that you can run e.g. nvim-container.sh file.txt and have file.txt opened inside the container
