{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  enableFor = hosts: lib.elem hostname hosts;
  disableFor = hosts: !lib.elem hostname hosts;
in
{
  # System
  dotfiles.programs.aerospace.enable = enableFor [ "MacBook-Pro-de-Healthium-6" ];

  # Shells
  dotfiles.programs.zsh.enable = true;

  # Terminals
  dotfiles.programs.ghostty.enable = enableFor [ "MacBook-Pro-de-Healthium-6" ];
  dotfiles.programs.wezterm.enable = false;

  # Editors & IDEs
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.vscode.enable = false;

  # Programming Languages
  dotfiles.programs.elixir.enable = false;
  dotfiles.programs.erlang.enable = false;

  # Dev Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.btop.enable = false;
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.codex.enable = false;
  dotfiles.programs.colima.enable = false;
  dotfiles.programs.cpufetch.enable = false;
  dotfiles.programs.ctop.enable = false;
  dotfiles.programs.curl.enable = false;
  dotfiles.programs.cursor.enable = false;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.docker.enable = false;
  dotfiles.programs.eza.enable = true;
  dotfiles.programs.fastfetch.enable = false;
  dotfiles.programs.fd.enable = true;
  dotfiles.programs.figlet.enable = false;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.glab.enable = false;
  dotfiles.programs.httpie.enable = false;
  dotfiles.programs.hyperfine.enable = false;
  dotfiles.programs.jj.enable = false;
  dotfiles.programs.jq.enable = false;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.onefetch.enable = false;
  dotfiles.programs.postgresql.enable = true;
  dotfiles.programs.ripgrep.enable = true;
  dotfiles.programs.shellcheck.enable = false;
  dotfiles.programs.shfmt.enable = false;
  dotfiles.programs.ssh.enable = true;
  dotfiles.programs.speedtest.enable = false;
  dotfiles.programs.unzip.enable = false;
  dotfiles.programs.wget.enable = false;
  dotfiles.programs.zed.enable = true;
  dotfiles.programs.zoxide.enable = true;

  #dotfiles.packages.enable = true;

  home.packages = with pkgs; [
    herdr
    imagemagick
    libyaml
  ];
}
