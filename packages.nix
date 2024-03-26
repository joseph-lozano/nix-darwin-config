{ pkgs }: {
  environment.systemPackages = [
    pkgs.gh
    pkgs.git
    pkgs.nixfmt
    pkgs.vim
  ];
}
