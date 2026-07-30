{
  config,
  lib,
  pkgs,
  hostname,
  users,
  ...
}:
{
  imports = [
    ./hosts/${hostname}.nix
  ];

  # ── Nix ─────────────────────────────────────────────────────────────────
  # nix-darwin manages the Nix installation and daemon on this machine, so it
  # owns /etc/nix/nix.conf. Enable flakes and nix-command here (vanilla Nix
  # ships with them off) — this is what lets `bin/update` and the flake-based
  # rebuild work.
  nix.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Determinate used to handle store upkeep for us; under plain nix-darwin we
  # schedule it ourselves. Collect garbage weekly (keeping 30 days of roots)
  # and hard-link identical store paths to reclaim space.
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

  nixpkgs.config.allowUnfree = true;

  # ── Networking / identity ─────────────────────────────────────────────
  # macOS lets DHCP rewrite the *transient* hostname (what the `hostname`
  # command returns) on every network it joins — that's why office Wi-Fi
  # keeps renaming this machine (Mac-335, Mac-410, …). We can't stop that,
  # and we no longer depend on it: `bin/rebuild` selects this config by the
  # logical label instead. Here we re-assert the *stable* names on every
  # switch so `scutil --get LocalHostName` always snaps back to that label
  # (its default detection source) and stops accumulating "(2)/(9)" suffixes.
  networking.computerName = hostname;
  networking.localHostName = hostname;
  # `networking.hostName` (persistent HostName) is intentionally left unset —
  # it's the one that tangles with the DHCP transient name we're avoiding.

  # ── Users ───────────────────────────────────────────────────────────────
  # Homebrew activation and user-scoped defaults run as the primary user.
  # macOS owns the account itself; we only point nix-darwin at it.
  system.primaryUser = lib.head (lib.attrNames users);

  # ── Shell ─────────────────────────────────────────────────────────────
  # Makes /etc/zshrc source the nix-darwin environment (PATH, profiles). The
  # zsh *configuration* still lives in home-manager.
  programs.zsh.enable = true;

  # Don't emit a bare `compinit` into /etc/zshrc. It runs before ~/.zshrc and,
  # once Homebrew's group-writable share/zsh/site-functions lands on fpath (via
  # `brew shellenv`), compaudit flags it as insecure and compinit interactively
  # prompts on every shell start. oh-my-zsh already runs `compinit -i`, which
  # silently skips insecure dirs, so the global call is redundant here.
  programs.zsh.enableGlobalCompInit = false;

  # ──────────────────────────────────────────────────────────────────────
  # Set to the nix-darwin version you first installed on this machine. A lower
  # value than the current release is fine; a higher one errors.
  system.stateVersion = 6;
}
