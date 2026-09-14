{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    pkgs.aerospace
  ];

  # Linked directly as the config AeroSpace reads. Gaps and workspace-to-monitor
  # assignments are plain tracked values here: AeroSpace can only change them by
  # editing its config (the CLI is read-only and there is no include mechanism),
  # so edit this file and rebuild.
  xdg.configFile."aerospace/aerospace.toml" = mkSymlink "aerospace.toml";
}
