# Joseph's Mac Setup

Personal, agent-first setup for Joseph's Apple-silicon Mac. It is intentionally fixed to the macOS user `joseph`, home directory `/Users/joseph`, and native `arm64`. It is not designed as a reusable multi-user framework.

This repository uses Homebrew Bundle, mise, GNU Stow, and small shell scripts. It does **not** install Nix, nix-darwin, Home Manager, Ansible, or Chezmoi.

## Install or Update

After macOS Setup Assistant creates the `joseph` account, open Terminal and run:

```sh
curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/joseph-lozano/nix-darwin-config/main/install.sh | sh
```

The same command handles both a fresh install and future updates. It:

1. validates the user, home directory, macOS, and Apple-silicon architecture;
2. waits for Apple Command Line Tools installation when needed;
3. clones this repository to `~/nix-darwin-config`, or fast-forwards an existing clean `main` checkout;
4. installs Homebrew and installs or upgrades the [`Brewfile`](Brewfile);
5. links genuinely static Git, SSH, Zsh, Starship, and Ghostty files with Stow;
6. installs Amp, Codex, mise, Node LTS, Aube, Pi, Plannotator, skills, and agent integrations using their supported ownership paths;
7. applies the macOS security, keyboard, shortcut, and Dock settings; and
8. runs [`scripts/verify.sh`](scripts/verify.sh) and fails if the expected setup is incomplete.

The update path refuses to overwrite a dirty checkout or merge a divergent branch. Homebrew upgrades declared software but does **not** run destructive `brew bundle cleanup`, so unrelated software is not silently removed.

Review [`install.sh`](install.sh) before piping it to a shell if desired. Keep the Mac connected to power and the internet during the first run. Restart after it completes.

## Ownership Model

| Owner | What it manages |
| --- | --- |
| Homebrew Bundle | Conventional CLI tools, GUI apps, Herdr, OrbStack, Docker Sandboxes, and the IntoneMono Nerd Font |
| Official installers | Amp, Codex, mise, and the Plannotator binary |
| mise | Node LTS and Aube; Node is the only global language runtime |
| npm under mise's Node | Pi's CLI |
| GNU Stow | Only static dotfiles committed under `stow/` |
| Setup scripts | macOS defaults, selected agent integrations, and static files sourced from Joseph's public config repositories |
| Applications | Credentials, sessions, trust, caches, package stores, and other mutable state |

The last boundary is deliberate. `~/.codex/config.toml` must remain writable because Codex stores project trust there. `~/.pi/agent/settings.json` must remain writable because Pi updates settings and package declarations. Amp, Herdr, Plannotator, Pi, Codex, Setapp, and mise data directories are not Stow-managed.

## Fresh Mac Checklist

### Account and security

- [ ] Sign in to the Apple Account and enable the desired iCloud services.
- [ ] Install all pending macOS updates.
- [ ] Enable and verify FileVault under **System Settings → Privacy & Security → FileVault**. Store the recovery key outside this repository.
- [ ] Configure Time Machine and complete its first backup.
- [ ] Sign in to 1Password. Under **Settings → Developer**, enable the SSH agent and **Integrate with 1Password CLI**. Under **Settings → Security**, enable Touch ID.
- [ ] Run `op vault list`, `gh auth login`, and `ssh -T git@github.com`.
- [ ] Create `~/.zshenv.local` with any local API keys. This file is not Stow-managed; login and non-interactive Zsh sessions source it from `.zshenv`.
- [ ] Run `amp`, `codex`, and `pi` once and complete each required sign-in. In Codex, run `/hooks`, review the Herdr and Plannotator commands, and trust them so Codex can run them. In Pi, use `/login` for the configured providers.

### Apps and permissions

1. **Setapp:** Sign in, review Favorites, then install TablePlus, CleanShot X, In Your Face, and only the other subscription apps still wanted. Do not install duplicate standalone Homebrew copies; Setapp should own their licensing and updates.
2. **CleanShot X:** Grant Screen Recording and other requested permissions. In **Settings → Shortcuts**, choose **Use System Default Shortcuts**. The setup frees `Command-Shift-3`, `Command-Shift-4`, and `Command-Shift-5` from Apple's screenshot service.
3. **Raycast:** Open **Settings → General**, select `Command-Space` as the Raycast hotkey, enable launch at login, and grant Accessibility. The script disables Spotlight's conflicting shortcut, but Raycast must claim it once inside the app.
4. **In Your Face:** Connect the intended Google Calendar account. Google OAuth and consent are intentionally interactive and cannot be safely provisioned by this repository.
5. **Tailscale:** Approve the VPN configuration, sign in to the intended tailnet, and confirm the app reports that it is connected. To use `tailscale` in Terminal, open Tailscale's **Settings**, find **CLI integration**, select **Show me how**, then **Install Now** and approve the administrator prompt.
6. **Obsidian:** Create or open the intended vault and select Obsidian Sync, iCloud Drive, or local-only storage. Install the [official Obsidian Web Clipper](https://obsidian.md/clipper) in each browser and select its vault and clipping folder.
7. **Handy:** Grant Microphone and Accessibility access, download a local transcription model, and choose a shortcut that does not conflict with Raycast or CleanShot X.
8. **Chrome and Choosy:** Create `Personal` and `Work` Chrome profiles and sign in. Add both profiles to Choosy, make Choosy the default browser handler, and create the desired routing rules. Profile auth, cookies, extensions, and sync state stay browser-owned.
9. **Postgres:** Open Postgres.app, initialize and start a local server, then connect TablePlus to it.
10. **OrbStack:** Open it once and approve its helper. It owns normal Docker and Compose workloads; Docker Desktop is intentionally absent.
11. **Rectangle Pro, Ghostty, ScreenFlow, and other apps:** Grant only the permissions needed for the desired features.
12. **Plannotator:** Restart Amp or run `plugins: reload`, restart Codex Desktop, and restart Pi so their installed integration files load. If Codex reports changed hooks after an update, use `/hooks` to review and trust the new definitions.

Setapp and most GUI apps do not synchronize every preference. Use each application's own settings sync or export when available.

### Docker Sandboxes

Docker Sandboxes (`sbx`) is independent of OrbStack and does not require Docker Desktop or a host Docker Engine. It runs each agent in its own microVM with a private Docker daemon.

```sh
sbx login
sbx secret set openai --oauth
cd ~/path/to/project
sbx run codex
```

OrbStack's images, containers, networks, and cache are separate from each `sbx` microVM.

## Runtime and Agent Setup

Login Zsh sessions load mise's command shims, and interactive sessions then activate mise followed by Aube. Aube creates project-aware shims for `node`, `npm`, `npx`, `pnpm`, `pnpx`, `yarn`, and `yarnpkg`; projects keep their existing supported lockfile format.

```sh
node --version
npm --version
aube --version
pi --version
mise doctor
```

Pi has an explicit writable setting equivalent to:

```json
{"npmCommand":["mise","exec","node@lts","--","npm"]}
```

That setting is why Pi package installation still finds real npm when Pi starts from a GUI, Herdr, or another child-process context. It does not depend only on an interactive shell alias.

The installer clones these public repositories into `~/.local/share` and fast-forwards them on later runs:

- [`joseph-lozano/skills`](https://github.com/joseph-lozano/skills), flattened into `~/.agents/skills` with per-skill links;
- [`joseph-lozano/pi`](https://github.com/joseph-lozano/pi), used for static Pi instructions, extensions, theme, and extension dependencies.

Pi credentials, sessions, `settings.json`, npm/git package stores, caches, and runtime files remain local and writable. The source repository's whole-directory `setup.sh` is intentionally not used because it would mix mutable state into the config checkout.

## Expected macOS Behavior

The setup:

- enables the application firewall, stealth mode, and automatic system/security updates;
- enables Touch ID for `sudo` and installs `pam-reattach` before `pam_tid` for local multiplexed terminal sessions; SSH sessions correctly fall back to password authentication;
- installs Rosetta 2 if missing;
- moves the Dock to the left, enables auto-hide, hides recents, and installs the selected Dock apps;
- keeps standard Command and Option behavior and clears stale HID remaps;
- reserves `Command-Space` for Raycast; and
- reserves Apple's default screenshot shortcuts for CleanShot X.

## Installed Workflow

The development workflow is intentionally agent-first:

- Cursor as the primary coding editor;
- bare Vim for Git commits, rebases, and other terminal editing;
- Amp, OpenAI Codex, and Pi as coding agents;
- ChatGPT as the desktop AI client;
- Herdr as the persistent terminal multiplexer;
- Plannotator for Amp, Codex, and Pi plan/code review;
- Docker Sandboxes for isolated agent execution and OrbStack for normal containers; and
- mise with only Node LTS globally, with Aube as the npm-family package manager.

Neovim, extra editors, Ollama, Claude tooling, Docker Desktop, VLC, Chrome Canary, Livebook, devenv, pre-commit, and gitmoji are intentionally absent.

The complete GUI list is in [`Brewfile`](Brewfile). Setapp-owned apps are listed only in the interactive checklist because installing standalone copies would bypass Setapp.

## Updates and Changes

Rerun the one-line installer to update the repository and every managed owner:

- `brew bundle` upgrades declared formulae and casks;
- official installers update Amp, Codex, mise, and Plannotator;
- mise refreshes Node LTS and Aube;
- npm refreshes Pi;
- Pi refreshes `pi-cursor-sdk` and the Plannotator extension; and
- the public skills and Pi config checkouts fast-forward to `main`.

`amp update` also works independently because `amp` resolves to the official writable installation, not a Nix or Homebrew package.

Ask an agent to edit this repository for lasting changes:

- add/remove conventional software in `Brewfile`;
- change static shell, Git, SSH, or Ghostty config under `stow/`;
- change system behavior in `scripts/macos.sh`;
- change agent ownership or integrations in `scripts/agents.sh`; and
- record interactive steps in this README.

Removing an entry from `Brewfile` does not uninstall it automatically because cleanup is intentionally disabled. Review and uninstall the old package explicitly.

## Validate Changes

Run static checks from the repository:

```sh
sh -n install.sh
bash -n scripts/*.sh
shellcheck install.sh scripts/*.sh
git diff --check
```

On the Mac, verify the realized setup without changing it:

```sh
./scripts/verify.sh
brew bundle check --file=./Brewfile
```

This Linux-hosted repository cannot execute or prove macOS defaults, PAM, Homebrew casks, or app permissions. Those are verified by the final Mac-side script and the interactive checklist.
