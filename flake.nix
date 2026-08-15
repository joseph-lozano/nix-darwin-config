{
  description = "Joseph's nix-darwin configuration";

  inputs = {
    self.submodules = true;
    agent-skills = {
      url = "github:joseph-lozano/skills";
      flake = false;
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    pi-config = {
      url = "path:vendor/pi";
      flake = false;
    };
    plannotator-source = {
      url = "github:backnotprop/plannotator/v0.27.3";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      agent-skills,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-cask,
      home-manager,
      pi-config,
      plannotator-source,
    }:
    let
      configuration = { pkgs, ... }: {
        imports = [
          (import ./system.nix { inherit self pkgs; })
          ./homebrew.nix
        ];

        # Determinate Nix manages the Nix installation and daemon.
        nix.enable = false;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfree = true;

        programs.zsh.enable = true;

        system.primaryUser = "joseph";

        users.users.joseph = {
          home = "/Users/joseph";
          shell = pkgs.zsh;
        };
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Josephs-MacBook-Pro
      darwinConfigurations."Josephs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = "joseph";
              autoMigrate = true;
              taps = {
                "homebrew/homebrew-cask" = homebrew-cask;
              };
            };
          }

          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              extraSpecialArgs = {
                inherit agent-skills pi-config plannotator-source;
              };
              useGlobalPkgs = true;
              users.joseph.imports = [ ./home.nix ];
            };
          }
        ];
      };

      checks.aarch64-darwin.default = self.darwinConfigurations."Josephs-MacBook-Pro".system;

      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt;
    };
}
