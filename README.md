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
5. Open Tailscale, approve its VPN configuration, sign in to the intended tailnet, and verify the connection with `tailscale status`.
6. Open Obsidian and create or open the intended vault. Choose Obsidian Sync, iCloud Drive, or local-only storage in the app rather than storing vault contents in this repository.
7. Install the [official Obsidian Web Clipper](https://obsidian.md/clipper) in each browser where it will be used, review its requested website access, then select the intended vault and clipping folder.

Setapp does not automatically sync every managed app's preferences. Use an app's own sync or settings export when it provides one.

## Finish Developer and Security Setup

After logging back in, install the globally declared Node LTS and Aube versions:

```sh
mise install
node --version
aube --version
exec zsh
```

New Zsh sessions activate Aube's shims for `node`, `npm`, `npx`, `pnpm`, `pnpx`, `yarn`, and `yarnpkg`. Aube preserves the project's existing supported lockfile format.

Then complete the steps that require an account, recovery key, backup destination, or macOS consent:

- [ ] Sign in to the Apple Account and enable the desired iCloud services.
- [ ] Enable FileVault in **System Settings → Privacy & Security → FileVault**, then store the recovery key somewhere other than this repository.
- [ ] Configure and run the first Time Machine backup.
- [ ] Sign in to 1Password. Under **Settings → Developer**, enable its SSH agent and **Integrate with 1Password CLI**; enable Touch ID under **Settings → Security**, then verify CLI access with `op vault list`.
- [ ] Authenticate GitHub with `gh auth login` and verify SSH access with `ssh -T git@github.com`.
- [ ] Run `amp` and complete its browser sign-in; connect it to Cursor from Amp's command palette if desired.
- [ ] Open Handy, grant Microphone and Accessibility access, download a local transcription model, and choose a shortcut that does not conflict with CleanShot X or Raycast.
- [ ] Review requested permissions for CleanShot X, Raycast, In Your Face, Ghostty, and other trusted apps instead of granting broad access preemptively.

Rosetta 2, the macOS application firewall, stealth mode, and automatic system and security updates are handled by the system configuration.

## Development Tools

The configured workflow is centered on agentic coding:

- Cursor desktop and CLI as the primary coding workspace
- Bare terminal Vim for `EDITOR`, `VISUAL`, Git commits, and other interactive prompts
- ChatGPT desktop app
- OpenAI Codex and Pi coding-agent CLIs
- Herdr terminal multiplexer for persistent agent sessions
- mise with Node LTS as the only global runtime and Aube with its shell shims as the package manager

Neovim, other additional editors, and Claude tooling are intentionally not installed.

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
