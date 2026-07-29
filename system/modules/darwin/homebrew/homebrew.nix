{
  config,
  lib,
  pkgs,
  ...
}:
{
  # NOTE: nix-darwin does NOT install Homebrew itself — it only drives
  # `brew bundle` to reconcile the declarations below with what's installed.
  # Install Homebrew first (once, manually):
  #   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # (or add the `nix-homebrew` flake to also manage the brew installation.)
  homebrew = {
    enable = true;

    # Homebrew's post-install step, which nix-darwin otherwise skips: emit
    # `eval "$(<prefix>/bin/brew shellenv zsh)"` into /etc/zshrc so `brew` and
    # its installed binaries land on the interactive shell's PATH (also sets
    # HOMEBREW_*, MANPATH, and completions).
    enableZshIntegration = true;

    # Standard Homebrew install on this machine (Apple Silicon default prefix).
    prefix = "/opt/homebrew";

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };

    taps = [ "agavra/tap" ];

    # CLI formulae. Prefer nixpkgs via home.packages; list here only what nix
    # lacks or what must come from Homebrew.
    brews = [
      "gmp"
      "libyaml"
      "openssl@3"
      "libmagic"
      "libffi"
      "readline"
      "zlib"

      "agavra/tap/tuicr"
    ];

    # GUI apps / casks.
    casks = [
      "1password-cli"
      "bruno"
      "ghostty"
      "openlogi"
      "raycast"
    ];

    # Mac App Store apps (requires the `mas` CLI). Format: "App Name" = <id>;
    masApps = { };
  };
}
