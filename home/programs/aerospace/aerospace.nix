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

  xdg.configFile."aerospace/aerospace.toml" = mkSymlink "aerospace.toml";
}
