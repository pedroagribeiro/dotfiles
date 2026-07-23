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

  # No NixOS layer here to set the login shell, so drop from bash's login
  # profile into zsh (interactive shells only; leaves scp/ssh-command alone).
  programs.bash = {
    enable = true;
    profileExtra = ''
      # Load runtime secrets kept out of the repo (e.g. CLAUDE_CODE_OAUTH_TOKEN).
      [ -r /root/.config/claude/env ] && . /root/.config/claude/env
      [[ $- == *i* && -z "$ZSH_VERSION" && -x "$HOME/.nix-profile/bin/zsh" ]] && exec "$HOME/.nix-profile/bin/zsh" -l
    '';
  };

  # Editors & IDEs
  dotfiles.programs.nvim.enable = true;

  # Dev Tools
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.docker.enable = true;
  dotfiles.programs.eza.enable = true;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.jq.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.ssh.enable = true;
  dotfiles.programs.zoxide.enable = true;
}
