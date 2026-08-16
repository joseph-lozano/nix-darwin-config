#!/bin/bash

set -euo pipefail

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

sync_repo() {
  local url="$1"
  local destination="$2"

  if [[ -e "$destination" ]]; then
    [[ -d "$destination/.git" ]] || fail "$destination exists but is not a Git checkout"
    [[ "$(git -C "$destination" branch --show-current)" == "main" ]] || fail "$destination must be on main"
    [[ -z "$(git -C "$destination" status --porcelain)" ]] || fail "$destination has local changes"
    git -C "$destination" fetch --prune origin main
    git -C "$destination" merge --ff-only origin/main
  else
    git clone "$url" "$destination"
  fi
}

link_static_file() {
  local source="$1"
  local destination="$2"

  mkdir -p "$(dirname "$destination")"
  if [[ -e "$destination" && ! -L "$destination" ]]; then
    fail "$destination exists and is not a managed symlink"
  fi
  ln -sfn "$source" "$destination"
}

replace_directory() {
  local source="$1"
  local destination="$2"
  local temporary="${destination}.tmp.$$"

  rm -rf "$temporary"
  cp -R "$source" "$temporary"
  rm -rf "$destination"
  mv "$temporary" "$destination"
}

export PATH="$HOME/.local/bin:$HOME/.amp/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.local/state"

printf '%s\n' "Installing or updating Amp, Codex, and mise from their official installers..."
curl --proto '=https' --tlsv1.2 -fsSL https://ampcode.com/install.sh | bash
curl --proto '=https' --tlsv1.2 -fsSL https://chatgpt.com/codex/install.sh \
  | CODEX_NON_INTERACTIVE=1 sh
curl --proto '=https' --tlsv1.2 -fsSL https://mise.run | sh

command -v mise >/dev/null 2>&1 || fail "mise was not found after installation"

printf '%s\n' "Installing Node LTS, Aube, and Pi..."
mise settings add idiomatic_version_file_enable_tools node
mise use --global node@lts aube@latest
mise install
mise exec node@lts -- npm install --global --ignore-scripts @earendil-works/pi-coding-agent
mise reshim

# Make mise tools and Aube's node/npm-family shims visible to this process and
# every child process started during the remainder of setup.
eval "$(mise activate bash)"
eval "$(aube activate bash)"

command -v pi >/dev/null 2>&1 || fail "Pi was not found after installation"
command -v npm >/dev/null 2>&1 || fail "Aube did not expose an npm shim"

pi_config_repo="$HOME/.local/share/joseph-pi-config"
skills_repo="$HOME/.local/share/joseph-agent-skills"
sync_repo https://github.com/joseph-lozano/pi.git "$pi_config_repo"
sync_repo https://github.com/joseph-lozano/skills.git "$skills_repo"

# Pi's custom extensions resolve exa-js and firecrawl relative to this checkout.
mise exec node@lts -- npm ci --prefix "$pi_config_repo"

pi_dir="$HOME/.pi/agent"
mkdir -p "$pi_dir/extensions" "$pi_dir/themes"
link_static_file "$pi_config_repo/AGENTS.md" "$pi_dir/AGENTS.md"
link_static_file "$pi_config_repo/cloak.json" "$pi_dir/cloak.json"

for source in "$pi_config_repo"/extensions/*.ts; do
  [[ "$(basename "$source")" == "herdr-agent-state.ts" ]] && continue
  link_static_file "$source" "$pi_dir/extensions/$(basename "$source")"
done
for source in "$pi_config_repo"/themes/*.json; do
  link_static_file "$source" "$pi_dir/themes/$(basename "$source")"
done

pi_settings="$pi_dir/settings.json"
if [[ ! -e "$pi_settings" ]]; then
  cp "$pi_config_repo/settings.json" "$pi_settings"
fi

# Pi mutates settings.json during normal use. Update only the package-manager
# command required for reliable child-process npm access and leave all other
# application-owned settings untouched.
pi_settings_tmp="${pi_settings}.tmp.$$"
jq '.npmCommand = ["mise", "exec", "node@lts", "--", "npm"]' \
  "$pi_settings" >"$pi_settings_tmp"
mv "$pi_settings_tmp" "$pi_settings"

skills_dir="$HOME/.agents/skills"
skills_state_dir="$HOME/.local/state/joseph-mac-setup"
skills_manifest="$skills_state_dir/personal-skills"
skills_manifest_new="${skills_manifest}.tmp.$$"
mkdir -p "$skills_dir" "$skills_state_dir"
: >"$skills_manifest_new"

for category in engineering productivity; do
  for source in "$skills_repo/skills/$category"/*; do
    [[ -d "$source" && -f "$source/SKILL.md" ]] || continue
    skill_name="$(basename "$source")"
    link_static_file "$source" "$skills_dir/$skill_name"
    printf '%s\n' "$skill_name" >>"$skills_manifest_new"
  done
done

if [[ -f "$skills_manifest" ]]; then
  while IFS= read -r skill_name; do
    if ! grep -Fqx "$skill_name" "$skills_manifest_new"; then
      destination="$skills_dir/$skill_name"
      if [[ -L "$destination" && "$(readlink "$destination")" == "$skills_repo"/* ]]; then
        rm "$destination"
      fi
    fi
  done <"$skills_manifest"
fi
sort -u "$skills_manifest_new" >"$skills_manifest"
rm "$skills_manifest_new"

printf '%s\n' "Installing the current Plannotator release and selected integrations..."
plannotator_version="$(
  curl --proto '=https' --tlsv1.2 -fsSL \
    https://api.github.com/repos/backnotprop/plannotator/releases/latest \
    | jq -er .tag_name
)"
curl --proto '=https' --tlsv1.2 -fsSL https://plannotator.ai/install.sh \
  | bash -s -- --version "$plannotator_version" --verify-attestation --minimal

plannotator_source="$(mktemp -d)"
trap 'rm -rf "$plannotator_source"' EXIT
git clone --depth 1 --filter=blob:none --sparse \
  --branch "$plannotator_version" \
  https://github.com/backnotprop/plannotator.git \
  "$plannotator_source/repo"
git -C "$plannotator_source/repo" sparse-checkout set apps/skills/core

for skill_name in plannotator-annotate plannotator-last plannotator-review; do
  replace_directory \
    "$plannotator_source/repo/apps/skills/core/$skill_name" \
    "$skills_dir/$skill_name"
done

amp_plugin_dir="$HOME/.config/amp/plugins"
amp_plugin_tmp="$(mktemp)"
mkdir -p "$amp_plugin_dir"
curl --proto '=https' --tlsv1.2 -fsSL \
  "https://raw.githubusercontent.com/backnotprop/plannotator/$plannotator_version/apps/amp-plugin/plannotator.ts" \
  -o "$amp_plugin_tmp"
install -m 0644 "$amp_plugin_tmp" "$amp_plugin_dir/plannotator.ts"
rm "$amp_plugin_tmp"

printf '%s\n' "Installing Pi packages and Herdr integrations..."
pi install npm:pi-cursor-sdk
pi install npm:@plannotator/pi-extension

mkdir -p "$HOME/.codex"
herdr integration install pi
herdr integration install codex

codex_hooks="$HOME/.codex/hooks.json"
[[ -s "$codex_hooks" ]] || printf '{}\n' >"$codex_hooks"
codex_hooks_tmp="${codex_hooks}.tmp.$$"
jq --arg command "$HOME/.local/bin/plannotator" '
  def is_managed_plannotator:
      .type == "command" and
      ((.command // "") == "plannotator" or ((.command // "") | endswith("/plannotator")));
  def is_custom_plannotator:
      .type == "command" and
      ((.command // "") | contains("plannotator")) and
      (is_managed_plannotator | not);
  .hooks = (.hooks // {}) |
  (.hooks.Stop // []) as $stop_hooks |
  (any($stop_hooks[]?.hooks[]?; is_managed_plannotator)) as $had_managed |
  (any($stop_hooks[]?.hooks[]?; is_custom_plannotator)) as $has_custom |
  .hooks.Stop = ([
    $stop_hooks[] |
    ([.hooks[]? | select(is_managed_plannotator)] | length) as $managed_count |
    if $managed_count == 0 then
      .
    else
      .hooks = [.hooks[] | select((is_managed_plannotator) | not)] |
      select((.hooks | length) > 0)
    end
  ] + if $had_managed or ($has_custom | not) then
    [{"hooks": [{
        "type": "command",
        "command": $command,
        "timeout": 345600
    }]}]
  else
    []
  end)
' "$codex_hooks" >"$codex_hooks_tmp"
mv "$codex_hooks_tmp" "$codex_hooks"

herdr_skill_dir="$skills_dir/herdr"
herdr_skill_tmp="${herdr_skill_dir}.tmp.$$"
rm -rf "$herdr_skill_tmp"
mkdir -p "$herdr_skill_tmp"
herdr --skill >"$herdr_skill_tmp/SKILL.md"
rm -rf "$herdr_skill_dir"
mv "$herdr_skill_tmp" "$herdr_skill_dir"

printf '%s\n' "Agent CLIs, writable configuration, integrations, and skills installed."
