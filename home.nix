{ pkgs, ... }: {
  imports = [
    ./home/git.nix
    ./home/zsh.nix
  ];

  home = {
    stateVersion = "24.05";

    sessionVariables = {
      PAGER = "less";
      CLICOLOR = 1;
      EDITOR = "cursor --wait";
      VISUAL = "cursor --wait";
      SSH_AUTH_SOCK = "$HOME/Library/Group\\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

    file = {
      ".p10k.zsh".source = ./home/p10k.zsh;

      ".config/ghostty/config".text = ''
        font-family="IntoneMono Nerd Font Mono"
        theme=catppuccin-mocha
        font-size=22
      '';
    };

    packages = [
      pkgs.bun
      pkgs.curl
      pkgs.devenv
      pkgs.ffmpeg
      pkgs.fastfetch
      pkgs.gh
      pkgs.git
      pkgs.glow
      pkgs.htop
      pkgs.jq
      pkgs.less
      pkgs.mise
      pkgs.pre-commit
      pkgs.tree
      pkgs.wget
      pkgs.yt-dlp
      pkgs.zoxide
      pkgs.zsh
      pkgs.zsh-powerlevel10k

      pkgs.nodejs_22
      pkgs."gitmoji-cli"
    ];
  };

  programs = {
    git = {
      enable = true;
      ignores = [ ".DS_Store" ];
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".IdentityAgent =
        "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

    zsh = {
      enable = true;
      shellAliases = {
        phx = "iex -S mix phx.server";
        pn = "pnpm";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };
      initContent = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ~/.p10k.zsh
        export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
      '';
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
