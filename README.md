# Nix Darwin Config

Personal nix-darwin configuration for Joseph's Apple-silicon Mac. It is intentionally fixed to:

- macOS short username: `joseph`
- Home directory: `/Users/joseph`
- Platform: `aarch64-darwin`
- Flake configuration: `Josephs-MacBook-Pro`

The `Josephs-MacBook-Pro` value is only the flake configuration's existing name. It does not set the computer's model or hostname, so use that exact value on the new MacBook Air too.

> [!WARNING]
> Activation manages Homebrew declaratively and uses `cleanup = "uninstall"`. Every Homebrew formula or cask not listed in this repository is removed during activation. That is harmless on a fresh Mac, but add future Homebrew software to the configuration before activating it.

## Bootstrap the Fresh Mac

### 1. Verify the Mac and account

Finish macOS Setup Assistant, install any pending macOS updates, and verify the account and architecture in Terminal:

```sh
whoami
uname -m
```

These commands must print `joseph` and `arm64`. Stop if either value differs; this configuration deliberately does not support another username or Intel Mac.

### 2. Install the command line tools

Start Apple's Command Line Tools installer:

```sh
xcode-select --install
```

Wait for the graphical installer to finish, then verify it before continuing:

```sh
xcode-select -p
git --version
```

### 3. Install Nix

Install [Determinate Nix](https://determinate.systems/install/). Determinate Nix owns the Nix installation and daemon; nix-darwin intentionally does not replace them.

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

When the installer finishes, quit and reopen Terminal so its environment is loaded, then verify:

```sh
nix --version
```

Do not install Homebrew separately. The first nix-darwin activation installs and manages Apple-silicon Homebrew through nix-homebrew.

### 4. Download and check the configuration

```sh
git clone https://github.com/joseph-lozano/nix-darwin-config.git
cd nix-darwin-config
git status --short --branch
```

The status should show a clean `main` branch tracking `origin/main`. Evaluate and build the complete system without activating it:

```sh
nix flake check --no-update-lock-file --show-trace
nix build --no-link --no-update-lock-file '.#darwinConfigurations.Josephs-MacBook-Pro.system'
```

### 5. Activate the system

The first activation downloads the declared Nix packages and Homebrew apps, installs Rosetta 2 when needed, and changes the system preferences described below. Keep the Mac connected to power and the internet.

```sh
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake '.#Josephs-MacBook-Pro'
```

Do not continue if this command reports an error. After it succeeds, restart the Mac, open Terminal, and verify the managed tools:

```sh
command -v darwin-rebuild brew mise
nix --version
brew --version
mise --version
```

## Finish Account and Security Setup

Complete the steps that require an account, recovery key, backup destination, or macOS consent:

- [ ] Sign in to the Apple Account and enable the desired iCloud services.
- [ ] Verify FileVault under **System Settings → Privacy & Security → FileVault**, enable it if needed, and store the recovery key somewhere other than this repository.
- [ ] Configure Time Machine and complete its first backup.
- [ ] Sign in to 1Password. Under **Settings → Developer**, enable its SSH agent and **Integrate with 1Password CLI**; enable Touch ID under **Settings → Security**, then verify CLI access with `op vault list`.
- [ ] Confirm that 1Password contains the SSH key used for GitHub and Git signing, then run `gh auth login` and verify SSH access with `ssh -T git@github.com`.
- [ ] Run `amp` and complete its browser sign-in; connect it to Cursor from Amp's command palette if desired.

## Finish App Setup

Some app setup is intentionally interactive because it depends on account authentication or private app settings:

1. Open Setapp and sign in. Review **Favorites** before installing anything because the repository cannot audit that account-managed list. Install TablePlus, CleanShot X, In Your Face, and only the other favorites still wanted; do not use **Install all** until obsolete favorites have been removed. Setapp's **Help → Quick Installation** is also available when migrating from another Mac.
2. Open CleanShot X, grant the requested macOS permissions, then choose **Settings → Shortcuts → Use System Default Shortcuts**. The system configuration frees these shortcuts for CleanShot:
   - `Command-Shift-3` — capture the full screen
   - `Command-Shift-4` — capture an area
   - `Command-Shift-5` — open CleanShot's all-in-one capture menu
3. Open **Raycast → Settings → General** and set the Raycast hotkey to `Command-Space`. The system configuration disables the conflicting Spotlight shortcut.
4. Open In Your Face and connect the Google account under its calendar settings. Google OAuth sign-in and consent must be completed interactively; credentials and authorization tokens are not stored in this repository.
5. Open Tailscale, approve its VPN configuration, sign in to the intended tailnet, and verify the connection with `tailscale status`.
6. Open Obsidian and create or open the intended vault. Choose Obsidian Sync, iCloud Drive, or local-only storage in the app rather than storing vault contents in this repository.
7. Install the [official Obsidian Web Clipper](https://obsidian.md/clipper) in each browser where it will be used, review its requested website access, then select the intended vault and clipping folder.
8. Open Handy, grant Microphone and Accessibility access, download a local transcription model, and choose a shortcut that does not conflict with CleanShot X or Raycast.
9. Open Google Chrome, create `Personal` and `Work` profiles, and sign in to each. Profile authentication, cookies, extensions, and sync state are intentionally not managed by Nix. In Choosy, use the add button to add both Chrome profiles, make Choosy the default browser handler, and create any desired work/personal routing rules.
10. Open Postgres, initialize and start a local server if needed, then connect TablePlus to it.
11. Review requested permissions for Rectangle Pro, Ghostty, and other trusted apps instead of granting broad access preemptively.
12. Restart Amp or run `plugins: reload`, restart Codex Desktop so its plan-review hook is loaded, then start Pi and run `/plannotator` to verify its extension.

Setapp does not automatically sync every managed app's preferences. Use an app's own sync or settings export when it provides one.

## Finish Runtime Setup

After restarting, install the globally declared Node LTS and Aube versions:

```sh
mise install
node --version
aube --version
exec zsh
```

New Zsh sessions activate Aube's shims for `node`, `npm`, `npx`, `pnpm`, `pnpx`, `yarn`, and `yarnpkg`. Aube preserves the project's existing supported lockfile format.

Install the dependencies used by the declarative Pi extensions:

```sh
npm ci --prefix ~/.pi/agent
```

Pi automatically installs the `pi-cursor-sdk` and pinned Plannotator extension packages declared by the combined configuration. Start `pi` and use `/login` for the configured xAI and Cursor providers. The Exa and Firecrawl extensions are optional and require `EXA_API_KEY` and `FIRECRAWL_API_KEY`, respectively; do not store those keys in this repository.

Pi updates `settings.json` during normal use. Home Manager refreshes that writable file from `joseph-lozano/pi` on each activation, so persistent settings changes should be committed to that repository before rebuilding this configuration.

Docker Sandboxes is independent of OrbStack's Docker engine. Authenticate its standalone `sbx` CLI and OpenAI access on the host:

```sh
sbx login
sbx secret set openai --oauth
```

Then run Codex for a project from that project's directory:

```sh
sbx run codex
```

`sbx` runs Codex in its own isolated microVM and stores the OpenAI credentials in the macOS keychain. OrbStack remains the Docker and Compose runtime outside these agent sandboxes.

## Expected System Behavior

The configuration also:

- enables the macOS application firewall, stealth mode, and automatic system and security updates
- enables Touch ID for `sudo`, including detached Herdr terminal sessions
- installs Rosetta 2 when it is missing
- moves the Dock to the left, hides it automatically, and sets the declared Dock app shortcuts
- swaps the left Command and left Option keys
- reserves `Command-Space` for Raycast and the standard screenshot shortcuts for CleanShot X

## Development Tools

The configured workflow is centered on agentic coding:

- Cursor desktop and CLI as the primary coding workspace
- Bare terminal Vim for `EDITOR`, `VISUAL`, Git commits, and other interactive prompts
- ChatGPT desktop app
- OpenAI Codex and Pi coding-agent CLIs
- Plannotator for local plan annotation and code review in Amp, Codex, and Pi
- Docker Sandboxes for running Codex in isolated microVMs and OrbStack for regular Docker and Compose workloads
- Herdr terminal multiplexer for persistent agent sessions
- mise with Node LTS as the only global runtime and Aube with its shell shims as the package manager

Neovim, other additional editors, and Claude tooling are intentionally not installed.

## Add or Remove Software

Ask an agent to make configuration changes rather than installing managed software manually:

- Add macOS applications and Homebrew casks in `homebrew.nix`.
- Add Nix-managed command-line tools in `home.nix`.
- Add global language runtimes in `programs.mise.globalConfig.tools` in `home.nix`. Node LTS is intentionally the only global runtime today.
- Add Setapp subscription apps to Setapp Favorites, not Homebrew, so Setapp continues to own their licenses and updates.
- Record browser extensions, sign-ins, permissions, and other interactive setup in this README.

Because Homebrew cleanup is enabled, a formula or cask installed manually but not declared in `homebrew.nix` is removed by the next activation.

## Update Software

Ask an agent to handle updates deliberately:

- Update `flake.lock` in a separate commit after reviewing current nix-darwin, Home Manager, nix-homebrew, and Nixpkgs changes.
- Verify every Homebrew cask still exists under its declared name; Homebrew occasionally renames casks.
- Let GUI applications with built-in updaters manage their routine releases. System activation intentionally does not force every Homebrew app to upgrade.
- Update the global Node LTS and Aube installations with `mise upgrade` when desired.
- Never change `system.stateVersion` or `home.stateVersion` during a routine update.

## Validate and Apply Changes

Evaluate and build changes without activating them:

```sh
nix fmt
nix flake check --no-update-lock-file --show-trace
nix build --no-link --no-update-lock-file '.#darwinConfigurations.Josephs-MacBook-Pro.system'
git diff --check
```

After reviewing a successful build, activate it:

```sh
sudo darwin-rebuild switch --flake '.#Josephs-MacBook-Pro'
```

After an intentional `nix flake update`, repeat the checks and build before activation.
