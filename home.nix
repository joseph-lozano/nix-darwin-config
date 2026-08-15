{ lib, pkgs, ... }: {
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

    file = {
      ".p10k.zsh".source = ./home/p10k.zsh;

      ".codex/skills/herdr".source = "${pkgs.herdr}/share/herdr/skills/herdr";

      ".config/ghostty/config".text = ''
        font-family="IntoneMono Nerd Font Mono"
        theme=catppuccin-mocha
        font-size=22
      '';

      ".pi/agent/skills/herdr".source = "${pkgs.herdr}/share/herdr/skills/herdr";
    };

    packages = [
      pkgs.amp-cli
      pkgs.codex
      pkgs.curl
      pkgs.devenv
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
