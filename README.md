# Nix Darwin Config

Personal nix-darwin configuration for an Apple-silicon Mac. It assumes a fresh macOS installation with the user named `joseph`.

## Bootstrap a New Mac

Install the Xcode command line tools:

```sh
xcode-select --install
```

Install [Determinate Nix](https://determinate.systems/nix-installer/):

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Clone and activate the configuration:

```sh
git clone https://github.com/joseph-lozano/nix-darwin-config.git
cd nix-darwin-config
sudo nix run nix-darwin/master -- switch --flake '.#Josephs-MacBook-Pro'
```

Log out and back in after the first activation.

## Development Tools

The configured workflow is centered on agentic coding:

- Cursor desktop and CLI, configured for `EDITOR`, `VISUAL`, and Git
- ChatGPT desktop app
- OpenAI Codex and Pi coding-agent CLIs
- Herdr terminal multiplexer for persistent agent sessions

Vim, Neovim, and Claude tooling are intentionally not installed.

## Make and Apply Changes

Evaluate and build changes without activating them:

```sh
nix flake check --no-update-lock-file --show-trace
darwin-rebuild build --flake '.#Josephs-MacBook-Pro'
```

After reviewing a successful build, activate it:

```sh
sudo darwin-rebuild switch --flake '.#Josephs-MacBook-Pro'
```

Update all pinned inputs deliberately with `nix flake update`, then repeat the check and build steps before activation. Do not change `system.stateVersion` or `home.stateVersion` during a routine input update.
