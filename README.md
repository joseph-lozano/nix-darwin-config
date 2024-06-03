# Nix Darwin Config
This assumes a fresh install of MacOS

## Install the command line tools
```zsh
xcode-select --install
```

## Install Nix with the [determinate systems](https://determinate.systems) installer
```zsh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Execute the flake
Note: This requires the user be named `joseph`
```zsh
nix run nix-darwin -- switch --flake github:/joseph-lozano/nix-darwin-config
```

## Log out and log back in.
