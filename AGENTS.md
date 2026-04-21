# AGENTS.md

## What This Repo Is

A Podman-based Neovim + tmux + OpenCode container. One script wires everything together; there is no Makefile, CI, or test suite.

## Running

```bash
./nvim-container.sh               # launch with current directory mounted
./nvim-container.sh /path/to/dir  # launch with a specific directory
```

The script auto-builds the image (`nvim-cont`) if it is missing or if `Containerfile`, `entrypoint.sh`, `NVIM_VERSION`, or `OPENCODE_VERSION` have changed (SHA256 hash stored as an image label).

## Forcing a Rebuild

Change `NVIM_VERSION` or `OPENCODE_VERSION` in `nvim-container.sh`, edit `Containerfile`/`entrypoint.sh`, or:

```bash
podman rmi nvim-cont
```

## Version Sync Requirement

`OPENCODE_VERSION` is set in **two places** that must stay in sync:
- `nvim-container.sh` (used at runtime to detect stale images)
- `Containerfile` (used at build time via `--build-arg`)

`NVIM_VERSION` is only in `nvim-container.sh`.

## Non-Obvious Constraints

- **Podman only.** `--userns=keep-id` is a Podman flag; the run command fails under Docker.
- **UID is baked into the image** via `--build-arg UID/GID`. Rebuilding on a machine with a different UID requires a fresh build (`podman rmi nvim-cont`).
- **`vim.pack` requires Neovim 0.12+.** Do not replace with lazy.nvim/packer without rewriting `config/nvim/lua/config/plugins.lua`.
- **Plugin init order is mandatory.** `config.plugins` must be `require()`-d first in `init.lua` — `vim.pack.add()` must run before any `require("plugin-name")` calls.
- **OSC 52 clipboard sets `vim.env.TMUX = nil` intentionally.** The workaround in `config/nvim/lua/config/clipboard.lua` forces a bare OSC 52 sequence instead of a tmux DCS passthrough. Do not remove it.
- **`downloads/` is `.gitignored`.** The nvim tarball is auto-downloaded on first use; a `.version` sidecar tracks the cached version.
- **Tree-sitter parsers compile on first launch.** `nvim-treesitter` is managed via `vim.pack`; `gcc` and `make` are installed in the image for this. Compiled parsers land in `~/.local/share/nvim/parser/` (host-mounted at `~/.local/share/nvim-cont`), so they survive image rebuilds. Ansible has no dedicated grammar — use `yaml`. Terraform uses the `hcl` grammar. Neovim 0.12 already bundles `c`, `lua`, `vim`, `markdown`, `markdown_inline`, `vimdoc`, and `query`.

## Validation

No automated tests. Run `./nvim-container.sh` and verify manually.
