#!/usr/bin/env bash
# nvim-container.sh

# Parse --personal / --work flags out of args before processing positional args.
GIT_PROFILE_FLAG=""
ARGS=()
for arg in "$@"; do
  case "$arg" in
    --personal) GIT_PROFILE_FLAG="personal" ;;
    --work)     GIT_PROFILE_FLAG="work" ;;
    *)          ARGS+=("$arg") ;;
  esac
done
set -- "${ARGS[@]}"

# Resolve git profile: flag > GIT_PROFILE env var > interactive prompt
GIT_PROFILE="${GIT_PROFILE_FLAG:-${GIT_PROFILE:-}}"
if [ -z "${GIT_PROFILE}" ]; then
  echo "Is this a personal or work repository?"
  select GIT_PROFILE in personal work; do
    [ -n "${GIT_PROFILE}" ] && break
    echo "Please select 1 or 2."
  done
fi

case "${GIT_PROFILE}" in
  personal)
    GIT_USER_NAME="godsmith"
    GIT_USER_EMAIL="j.godsmith@proton.me"
    ;;
  work)
    GIT_USER_NAME="Joel Godfrey-Smith"
    GIT_USER_EMAIL="joel.n.godfrey-smith.ctr@us.navy.mil"
    ;;
  *)
    echo "Error: GIT_PROFILE must be 'personal' or 'work', got '${GIT_PROFILE}'"
    exit 1
    ;;
esac

CONTAINER_USER=$(id -un 2>/dev/null || echo "dev")
TARGET=$(realpath "${1:-.}")  # resolve to absolute path, default to current dir
TARGET_DIR=$(basename "${TARGET}")  # directory name used as the mount point inside the container
SCRIPT_DIR="$(dirname "$(realpath "$0")")" # realpath on $0 resolves this script's actual location regardless of where you call it from
IMAGE_NAME="nvim-cont"

NVIM_VERSION=0.12.0
OPENCODE_VERSION=1.14.19
LAZYGIT_VERSION=0.61.1
DELTA_VERSION=0.19.2

CONTAINERFILE_HASH=$(printf '%s %s %s %s %s %s' \
  "$(sha256sum "${SCRIPT_DIR}/Containerfile" | cut -d' ' -f1)" \
  "$(sha256sum "${SCRIPT_DIR}/entrypoint.sh" | cut -d' ' -f1)" \
  "${NVIM_VERSION}" "${OPENCODE_VERSION}" "${LAZYGIT_VERSION}" "${DELTA_VERSION}" \
  | sha256sum | cut -d' ' -f1)
CURRENT_HASH=$(podman image inspect ${IMAGE_NAME} --format '{{index .Labels "containerfile-hash"}}' 2>/dev/null)

if [ "${CURRENT_HASH}" != "${CONTAINERFILE_HASH}" ]; then
  echo "Image '${IMAGE_NAME}' not found or a build change has been detected, building..."

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

  download_if_needed \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz" \
    "${DOWNLOADS_DIR}/lazygit.tar.gz" \
    "${LAZYGIT_VERSION}"

  download_if_needed \
    "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    "${DOWNLOADS_DIR}/delta.tar.gz" \
    "${DELTA_VERSION}"

  # Detect AVX2 support on the host and download the matching OpenCode binary.
  # The container runs on the same CPU, so the host check is authoritative.
  if grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
    OPENCODE_ARCH_SUFFIX=""
  else
    OPENCODE_ARCH_SUFFIX="-baseline"
  fi

  download_if_needed \
    "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/opencode-linux-x64${OPENCODE_ARCH_SUFFIX}.tar.gz" \
    "${DOWNLOADS_DIR}/opencode.tar.gz" \
    "${OPENCODE_VERSION}"

  podman build -t ${IMAGE_NAME} \
    --label "containerfile-hash=${CONTAINERFILE_HASH}" \
    --build-arg USERNAME=${CONTAINER_USER} \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    "${SCRIPT_DIR}"
fi

# Build a gitconfig from the template by substituting the user name and email for the selected profile.
# A temp file is used so Podman has a real file path to bind-mount. The trap ensures it is always
# deleted on exit, even if the script is interrupted.
GITCONFIG_TMP=$(mktemp)
trap "rm -f ${GITCONFIG_TMP}" EXIT
sed -e "s/__GIT_USER_NAME__/${GIT_USER_NAME}/" \
    -e "s/__GIT_USER_EMAIL__/${GIT_USER_EMAIL}/" \
    "${SCRIPT_DIR}/config/git/gitconfig.template" > "${GITCONFIG_TMP}"

# If NODE_EXTRA_CA_CERTS points to an existing file, mount it into the container home directory
NODE_CA_ARGS=()
if [ -f "${NODE_EXTRA_CA_CERTS}" ]; then
  NODE_CA_FILENAME=$(basename "${NODE_EXTRA_CA_CERTS}")
  NODE_CA_CONTAINER_PATH="/home/${CONTAINER_USER}/${NODE_CA_FILENAME}"
  NODE_CA_ARGS+=(-v "${NODE_EXTRA_CA_CERTS}:${NODE_CA_CONTAINER_PATH}:ro,z")
  NODE_CA_ARGS+=(-e "NODE_EXTRA_CA_CERTS=${NODE_CA_CONTAINER_PATH}")
fi

# Ensure persistent data and state directories exist on the host for each tool.
# All directories are namespaced under ~/.local/{share,state}/nvim-cont/ to keep
# the host tidy. Each tool gets its own subdirectory.
mkdir -p \
  "${HOME}/.local/share/${IMAGE_NAME}/nvim" \
  "${HOME}/.local/share/${IMAGE_NAME}/opencode" \
  "${HOME}/.local/state/${IMAGE_NAME}/nvim" \
  "${HOME}/.local/state/${IMAGE_NAME}/opencode" \
  "${HOME}/.local/state/${IMAGE_NAME}/lazygit"

# --userns=keep-id ensures the in-container user owns the mounted files, Podman-specific - doesn't exist in Docker 
# :z on volume mounts tells Podman to relabel the files for SELinux, :z (lowercase) if you want the label shared across multiple containers, :Z (uppercase) for private to this container
podman run --rm -it \
  --userns=keep-id \
  --hostname "${IMAGE_NAME}" \
  -v "${TARGET}:/home/${CONTAINER_USER}/${TARGET_DIR}:z" \
  -v "${SCRIPT_DIR}/config/lazygit:/home/${CONTAINER_USER}/.config/lazygit:z" \
  -v "${SCRIPT_DIR}/config/nvim:/home/${CONTAINER_USER}/.config/nvim:z" \
  -v "${SCRIPT_DIR}/config/opencode:/home/${CONTAINER_USER}/.config/opencode:z" \
  -v "${SCRIPT_DIR}/config/tmux:/home/${CONTAINER_USER}/.config/tmux:z" \
  -v "${SCRIPT_DIR}/config/ssh/checkhostip.conf:/etc/ssh/ssh_config.d/checkhostip.conf:ro,z" \
  -v "${SCRIPT_DIR}/config/bash/.bashrc:/home/${CONTAINER_USER}/.bashrc:ro,z" \
  -v "${HOME}/.local/share/${IMAGE_NAME}/nvim:/home/${CONTAINER_USER}/.local/share/nvim:z" \
  -v "${HOME}/.local/share/${IMAGE_NAME}/opencode:/home/${CONTAINER_USER}/.local/share/opencode:z" \
  -v "${HOME}/.local/state/${IMAGE_NAME}/nvim:/home/${CONTAINER_USER}/.local/state/nvim:z" \
  -v "${HOME}/.local/state/${IMAGE_NAME}/opencode:/home/${CONTAINER_USER}/.local/state/opencode:z" \
  -v "${HOME}/.local/state/${IMAGE_NAME}/lazygit:/home/${CONTAINER_USER}/.local/state/lazygit:z" \
  -v "${HOME}/.ssh:/home/${CONTAINER_USER}/.ssh:z" \
  -v "${GITCONFIG_TMP}:/home/${CONTAINER_USER}/.gitconfig:ro,z" \
  "${NODE_CA_ARGS[@]}" \
  -e ANTHROPIC_PROVIDER_NAME="${ANTHROPIC_PROVIDER_NAME}" \
  -e ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL}" \
  -e ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN}" \
  -e TERM=xterm-256color \
  -e COLORTERM=truecolor \
  -e LANG=C.UTF-8 \
  -e EDITOR=nvim \
  -w "/home/${CONTAINER_USER}/${TARGET_DIR}" \
  ${IMAGE_NAME} \
  /home/${CONTAINER_USER}/${TARGET_DIR}

