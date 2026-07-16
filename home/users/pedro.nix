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
  # Desktop Environment
  dotfiles.programs.gnome.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.gnome.extensions = {
    accent-directories.enable = true;
    auto-move-windows.enable = true;
    blur-my-shell.enable = true;
    caffeine.enable = true;
    color-picker.enable = true;
    draw-on-gnome.enable = true;
    glocalsend.enable = enableFor [ "thinkpad" ];
    pop-shell.enable = true;
    rudra.enable = false;
    smart-home.enable = true;
    space-bar.enable = true;
    top-bar-organizer.enable = true;
    vitals.enable = true;
    wake-on-lan.enable = true;
    # wallpaper-slideshow.enable = enableFor [ "thinkpad" ];
    wiggle.enable = true;
  };

  dotfiles.programs.hyprland.enable = false;

  # Shells
  dotfiles.programs.zsh.enable = true;

  # Desktop Launchers & App Switchers
  dotfiles.programs.vicinae.enable = enableFor [ "thinkpad" ];

  # Terminals
  dotfiles.programs.ghostty.enable = enableFor [ "thinkpad" ];
  # dotfiles.programs.wezterm.enable = false;

  # Editors & IDEs
  dotfiles.programs.fonts.enable = enableFor [ "thinkpad" ];
  # dotfiles.programs.jetbrains.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.nvim.enable = true;
  dotfiles.programs.vscode.enable = enableFor [ "thinkpad" ];
  # dotfiles.programs.zed.enable = enableFor [ "thinkpad" ];

  # Programming Languages
  # dotfiles.programs.elixir.enable = true;
  # dotfiles.programs.erlang.enable = true;
  # dotfiles.programs.flutter.enable = true;
  dotfiles.programs.golang.enable = true;
  # dotfiles.programs.haskell.enable = true;
  dotfiles.programs.nodejs.enable = true;
  dotfiles.programs.python.enable = true;
  dotfiles.programs.ruby.enable = true;

  # Dev Tools
  dotfiles.programs.bat.enable = true;
  dotfiles.programs.bruno.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.btop.enable = true;
  dotfiles.programs.claude.enable = true;
  dotfiles.programs.codex.enable = true;
  # dotfiles.programs.colima.enable = enableFor [ "Remote-Nelson-Estevao" ];
  # dotfiles.programs.copilot.enable = true;
  dotfiles.programs.cpufetch.enable = true;
  dotfiles.programs.ctop.enable = true;
  dotfiles.programs.curl.enable = true;
  # dotfiles.programs.cursor.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.devcontainer.enable = true;
  dotfiles.programs.direnv.enable = true;
  dotfiles.programs.docker.enable = true;
  dotfiles.programs.exiftool.enable = true;
  dotfiles.programs.eza.enable = true;
  dotfiles.programs.fastfetch.enable = true;
  dotfiles.programs.fd.enable = true;
  dotfiles.programs.figlet.enable = true;
  dotfiles.programs.fzf.enable = true;
  dotfiles.programs.git.enable = true;
  dotfiles.programs.glab.enable = true;
  dotfiles.programs.glow.enable = true;
  dotfiles.programs.herdr.enable = true;
  dotfiles.programs.httpie.enable = true;
  dotfiles.programs.hyperfine.enable = true;
  dotfiles.programs.jj.enable = true;
  dotfiles.programs.jq.enable = true;
  dotfiles.programs.kamal.enable = true;
  dotfiles.programs.mise.enable = true;
  dotfiles.programs.mysql.enable = false;
  # dotfiles.programs.ngrok.enable = true;
  dotfiles.programs.onefetch.enable = true;
  dotfiles.programs.opencode.enable = true;
  # dotfiles.programs.pandoc.enable = true;
  # dotfiles.programs.podman.enable = false;
  dotfiles.programs.rclone.enable = true;
  dotfiles.programs.restic.enable = true;
  dotfiles.programs.ripgrep.enable = true;
  dotfiles.programs.shellcheck.enable = true;
  dotfiles.programs.shfmt.enable = true;
  dotfiles.programs.speedtest.enable = true;
  dotfiles.programs.sqlite.enable = true;
  dotfiles.programs.ssh.enable = true;
  # dotfiles.programs.terraform.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.unoconv.enable = true;
  dotfiles.programs.unzip.enable = true;
  dotfiles.programs.watchman.enable = true;
  dotfiles.programs.wget.enable = true;
  dotfiles.programs.zellij.enable = true;
  dotfiles.programs.zoxide.enable = true;

  # Typesetting
  # dotfiles.programs.latex.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.typst.enable = true;

  # Desktop Applications
  dotfiles.programs.beeper.enable = enableFor [ "thinkpad" ];
  # dotfiles.programs.bitwarden.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.onepassword.enable = true;
  dotfiles.programs.calibre.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.chrome.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.digikam.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.espanso.enable = false;
  dotfiles.programs.gimp.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.inkscape.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.libreoffice.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.localsend.enable = enableFor [ "thinkpad" ];
  # dotfiles.programs.obsidian.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.pdfmixtool.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.pinta.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.thunderbird.enable = enableFor [ "thinkpad" ];
  # dotfiles.programs.typora.enable = enableFor [ "thinkpad" ];
  # dotfiles.programs.vivaldi.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.wine.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.zeal.enable = enableFor [ "thinkpad" ];
  dotfiles.programs.zen.enable = enableFor [ "thinkpad" ];

  dotfiles.packages.enable = true;
}
