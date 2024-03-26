{ pkgs }: {
  environment.systemPackages = [
    pkgs.git
    pkgs.vim
    pkgs.nixfmt
    pkgs.gh
    pkgs.slack
    pkgs.discord
    pkgs.raycast
  ];
}
