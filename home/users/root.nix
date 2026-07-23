{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
{
  home.homeDirectory = lib.mkForce "/root";

  # Shells
  dotfiles.programs.zsh.enable = true;

  # Editors & IDEs
  dotfiles.programs.nvim.enable = true;

  # Dev Tools
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.docker.enable = true;
  dotfiles.programs.eza.enable = true;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.ssh.enable = true;
  dotfiles.programs.zoxide.enable = true;
}
