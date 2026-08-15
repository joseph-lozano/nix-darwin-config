{
  agent-skills,
  lib,
  pi-config,
  pkgs,
  ...
}:
let
  skillFilesFrom =
    directory:
    lib.mapAttrs' (
      name: _:
      lib.nameValuePair ".agents/skills/${name}" {
        source = "${directory}/${name}";
      }
    ) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir directory));

  agentSkillFiles =
    skillFilesFrom "${agent-skills}/skills/engineering"
    // skillFilesFrom "${agent-skills}/skills/productivity";

  piExtensionFiles =
    lib.mapAttrs'
      (
        name: _:
        lib.nameValuePair ".pi/agent/extensions/${name}" {
          source = "${pi-config}/extensions/${name}";
        }
      )
      (
        lib.filterAttrs (name: type: type == "regular" && name != "herdr-agent-state.ts") (
          builtins.readDir "${pi-config}/extensions"
        )
      );
in
{
  imports = [
    ./home/git.nix
    ./home/zsh.nix
  ];

  home = {
    stateVersion = "24.05";

    sessionVariables = {
      PAGER = "less";
      CLICOLOR = 1;
      EDITOR = "vim";
      VISUAL = "vim";
      SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

    file =
      agentSkillFiles
      // piExtensionFiles
      // {
        ".p10k.zsh".source = ./home/p10k.zsh;

        ".codex/skills/herdr".source = "${pkgs.herdr}/share/herdr/skills/herdr";

        ".config/ghostty/config".text = ''
          font-family="IntoneMono Nerd Font Mono"
          theme=catppuccin-mocha
          font-size=22
        '';

        ".pi/agent/AGENTS.md".source = "${pi-config}/AGENTS.md";
        ".pi/agent/cloak.json".source = "${pi-config}/cloak.json";
        ".pi/agent/package-lock.json".source = "${pi-config}/package-lock.json";
        ".pi/agent/package.json".source = "${pi-config}/package.json";
        ".pi/agent/prompts" = {
          source = "${pi-config}/prompts";
          recursive = true;
        };
        ".pi/agent/skills/herdr".source = "${pkgs.herdr}/share/herdr/skills/herdr";
        ".pi/agent/themes" = {
          source = "${pi-config}/themes";
          recursive = true;
        };
      };

    packages = [
      pkgs.amp-cli
      pkgs.codex
      pkgs.curl
      pkgs.devenv
      pkgs.docker-sbx
      pkgs.ffmpeg
      pkgs.fastfetch
      pkgs.gh
      pkgs.git
      pkgs.glow
      pkgs.herdr
      pkgs.htop
      pkgs.jq
      pkgs.less
      pkgs.pi-coding-agent
      pkgs.tree
      pkgs.vim
      pkgs.wget
      pkgs.yt-dlp
      pkgs.zoxide
      pkgs.zsh
      pkgs.zsh-powerlevel10k
    ];
  };

  home.activation.installPiConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    pi_dir="$HOME/.pi/agent"
    $DRY_RUN_CMD mkdir -p "$pi_dir/extensions"
    $DRY_RUN_CMD install -m 0644 ${pi-config}/settings.json "$pi_dir/settings.json"
    $DRY_RUN_CMD ${pkgs.herdr}/bin/herdr integration install pi
  '';

  programs = {
    mise = {
      enable = true;
      enableMutableConfig = true;
      enableZshIntegration = true;
      globalConfig.tools = {
        aube = "latest";
        node = "lts";
      };
    };

    git = {
      enable = true;
      ignores = [ ".DS_Store" ];
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".IdentityAgent = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

    zsh = {
      enable = true;
      shellAliases = {
        phx = "iex -S mix phx.server";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };
      initContent = lib.mkMerge [
        ''
          eval "$(/opt/homebrew/bin/brew shellenv)"
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          source ~/.p10k.zsh
        ''
        (lib.mkAfter ''
          if command -v aube >/dev/null 2>&1; then
            eval "$(aube activate zsh)"
          fi
        '')
      ];
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
