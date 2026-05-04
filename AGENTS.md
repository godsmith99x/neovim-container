# AGENTS.md

## Documentation Requirement

**All agents must keep documentation up to date.** Any time you make a change to this repo — adding a plugin, changing a version, refactoring files, adding a binary, etc. — update AGENTS.md and any other affected documentation in the same response. Do not leave documentation out of sync with the code.

## What This Repo Is

A Podman-based Neovim + tmux + OpenCode container. One script wires everything together; there is no Makefile, CI, or test suite.

## Running

```bash
./nvim-container.sh               # launch with current directory mounted (prompts for git profile)
./nvim-container.sh /path/to/dir  # launch with a specific directory
./nvim-container.sh --personal    # skip prompt, use personal git identity
./nvim-container.sh --work        # skip prompt, use work git identity
./nvim-container.sh --tmux        # use tmux-tabs.sh entrypoint (default: neovim.sh)
./nvim-container.sh --config=lazyvim  # use lazyvim config (default: custom)
./nvim-container.sh --skip-build  # skip image build; fail if image does not exist
./nvim-container.sh --help        # show usage and exit
GIT_PROFILE=personal ./nvim-container.sh  # skip prompt via env var
```

The `--personal`/`--work` flags and the `GIT_PROFILE` env var are all equivalent ways to skip the interactive prompt. If none are provided, the script asks at startup.

The `--tmux` flag selects the `tmux-tabs.sh` entrypoint (creates a tmux session with neovim, opencode, and term windows). Without it, the default `neovim.sh` entrypoint launches neovim directly.

The `--config` flag selects the Neovim config to use at runtime: `custom` (default), `lazyvim`, or `nvchad`. The selected config directory under `config/nvim/` is mounted to `~/.config/nvim` in the container, and its corresponding data/state directories are used under `~/.local/{share,state}/nvim-cont/nvim/`.

The script auto-builds the image (`nvim-cont`) if it is missing or if `Containerfile`, `entrypoint.sh`, `NVIM_VERSION`, `OPENCODE_VERSION`, `LAZYGIT_VERSION`, or `DELTA_VERSION` have changed (SHA256 hash stored as an image label). Changes to scripts in `entrypoints/` do **not** trigger rebuilds — they are mounted from the host at runtime.

On launch, `entrypoint.sh` validates and runs the script specified by the `ENTRYPOINT` environment variable. The default `neovim.sh` entrypoint launches neovim directly. The `tmux-tabs.sh` entrypoint creates a single tmux session (`neovim`) with three named windows:
- **Window 1 (`nvim-v`):** neovim — drops to bash when neovim exits (starts here)
- **Window 2 (`opencode-k`):** opencode — drops to bash when opencode exits
- **Window 3 (`term-h`):** shell — ready for ad-hoc use

## Forcing a Rebuild

Change `NVIM_VERSION`, `OPENCODE_VERSION`, `LAZYGIT_VERSION`, or `DELTA_VERSION` in `nvim-container.sh`, edit `Containerfile`/`entrypoint.sh`, or:

```bash
podman rmi nvim-cont
```

## Version Sync Requirement

`NVIM_VERSION`, `OPENCODE_VERSION`, `LAZYGIT_VERSION`, and `DELTA_VERSION` are all only in `nvim-container.sh`.

## Entrypoint Scripts

Entrypoint scripts live in `entrypoints/` on the host and are mounted into the container at `/usr/local/bin/entrypoints/`. `entrypoint.sh` acts as a dispatcher: it validates the `ENTRYPOINT` env var and runs the selected script with arguments forwarded.

Available entrypoints:
- **`neovim.sh`** (default) — launches neovim directly
- **`tmux-tabs.sh`** (via `--tmux` flag) — creates tmux session with neovim, opencode, and term windows

To add a new entrypoint: create `entrypoints/<name>.sh`, make it executable, and pass `-e ENTRYPOINT="/usr/local/bin/entrypoints/<name>.sh"` to the container.

## Plugin Structure

Neovim configs are stored under `config/nvim/` with one subdirectory per config: `custom/`, `lazyvim/`, `nvchad/`. The selected config (via `--config` flag) is mounted to `~/.config/nvim` in the container at runtime.

Plugins for the `custom` config are declared and configured under `config/nvim/custom/lua/config/plugins/`:

```
plugins/
  init.lua         — vim.pack.add() declarations + require() calls for each plugin
  monokai.lua      — monokai-pro.nvim colorscheme setup
  treesitter.lua   — nvim-treesitter parser list and highlight config
  lazygit.lua      — lazygit.nvim floating terminal + <leader>g keymap
```

`require("config.plugins")` in `config/nvim/custom/init.lua` resolves to `plugins/init.lua` via Lua's directory `init.lua` convention. **When adding a new plugin to the custom config: declare its source in `plugins/init.lua` inside `vim.pack.add()`, create a `plugins/<name>.lua` config file, and add a `require()` call for it at the bottom of `plugins/init.lua`.**

## Non-Obvious Constraints

- **Podman only.** `--userns=keep-id` is a Podman flag; the run command fails under Docker.
- **UID is baked into the image** via `--build-arg UID/GID`. Rebuilding on a machine with a different UID requires a fresh build (`podman rmi nvim-cont`).
- **`vim.pack` requires Neovim 0.12+.** Do not replace with lazy.nvim/packer without rewriting the plugin structure under `config/nvim/<config>/lua/config/plugins/`.
- **Plugin init order is mandatory.** `config.plugins` must be `require()`-d first in `init.lua` — `vim.pack.add()` must run before any `require("plugin-name")` calls.
- **OSC 52 clipboard sets `vim.env.TMUX = nil` intentionally.** The workaround in `config/nvim/custom/lua/config/clipboard.lua` forces a bare OSC 52 sequence instead of a tmux DCS passthrough. Do not remove it.
- **`downloads/` is `.gitignored`.** Tarballs are auto-downloaded on first use; a `.version` sidecar tracks the cached version for each file.
- **OpenCode is installed from host-preloaded tarballs.** `nvim-container.sh` detects AVX2 support on the host CPU (`/proc/cpuinfo`) and downloads either `opencode-linux-x64.tar.gz` or `opencode-linux-x64-baseline.tar.gz`, saving it as `downloads/opencode.tar.gz`. `Containerfile` installs it to `/usr/local/bin/opencode` like all other tools.
- **Tree-sitter parsers compile on first launch.** `nvim-treesitter` is managed via `vim.pack`; `gcc` and `make` are installed in the image for this. Compiled parsers land in `~/.local/share/nvim/parser/` (host-mounted at `~/.local/share/nvim-cont/nvim`), so they survive image rebuilds. Ansible has no dedicated grammar — use `yaml`. Terraform uses the `hcl` grammar. Neovim 0.12 already bundles `c`, `lua`, `vim`, `markdown`, `markdown_inline`, `vimdoc`, and `query`.
- **`ncurses-term` provides extended terminfo terminal definitions** for OpenCode's TUI. Added alongside OpenCode CLI installation in commit cc6abe54 to ensure proper rendering of OpenCode's terminal interface inside the container.
- **lazygit binary is installed at image build time** from a pre-downloaded tarball in `downloads/`. The version is controlled by `LAZYGIT_VERSION` in `nvim-container.sh` and is included in the image hash.
- **lazygit config is at `config/lazygit/config.yml`** and is mounted into the container at `~/.config/lazygit/`. The file must exist or lazygit will error on launch.
- **Git identity is injected at runtime via `config/git/gitconfig.template`.** The template contains `__GIT_USER_NAME__` and `__GIT_USER_EMAIL__` placeholders. On each launch, `nvim-container.sh` substitutes the correct values using `sed` (based on the selected profile), writes the result to a `mktemp` file, and mounts it as `~/.gitconfig` in the container. The temp file is deleted on script exit via `trap ... EXIT`. All other git settings (delta pager, merge config, etc.) live only in the template — there is no separate per-profile copy. To change shared git settings, edit `config/git/gitconfig.template` only.
- **`~/.ssh` is mounted read-write** so that the container can update `known_hosts` when connecting to new hosts. This persists across container rebuilds.
- **SSH `CheckHostIP` is disabled** via `config/ssh/checkhostip.conf` (mounted at `/etc/ssh/ssh_config.d/checkhostip.conf`). Without this, SSH records both hostname and IP in `known_hosts`, causing re-prompts when GitHub rotates its IPs across container restarts.

## Tmux Key Bindings

All bindings use the tmux prefix (default `Ctrl-b` or alternate `M-z`):

- **`<prefix>v`:** go to neovim window
- **`<prefix>k`:** go to opencode window
- **`<prefix>h`:** go to term window
- **`<prefix>l`:** switch to last window (tmux default — quick toggle between the two most recently viewed windows)

None of these bindings override default tmux prefix keys.

## Validation

No automated tests. Run `./nvim-container.sh` and verify manually.
