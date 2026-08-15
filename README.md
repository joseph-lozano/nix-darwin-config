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

## Finish App Setup

Some app setup is intentionally interactive because it depends on account authentication or private app settings:

1. Open Setapp and sign in. In **Favorites**, click **Install all** to install the saved app collection, including TablePlus, CleanShot X, and In Your Face. Setapp's **Help → Quick Installation** is also available when migrating from another Mac.
2. Open CleanShot X, grant the requested macOS permissions, then choose **Settings → Shortcuts → Use System Default Shortcuts**. The system configuration frees these shortcuts for CleanShot:
   - `Command-Shift-3` — capture the full screen
   - `Command-Shift-4` — capture an area
   - `Command-Shift-5` — open CleanShot's all-in-one capture menu
3. Open **Raycast → Settings → General** and set the Raycast hotkey to `Command-Space`. The system configuration disables the conflicting Spotlight shortcut.
4. Open In Your Face and connect the Google account under its calendar settings. Google OAuth sign-in and consent must be completed interactively; credentials and authorization tokens are not stored in this repository.

Setapp does not automatically sync every managed app's preferences. Use an app's own sync or settings export when it provides one.

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
nix fmt
nix flake check --no-update-lock-file --show-trace
darwin-rebuild build --flake '.#Josephs-MacBook-Pro'
```

After reviewing a successful build, activate it:

```sh
sudo darwin-rebuild switch --flake '.#Josephs-MacBook-Pro'
```

Update all pinned inputs deliberately with `nix flake update`, then repeat the check and build steps before activation. Do not change `system.stateVersion` or `home.stateVersion` during a routine input update.
