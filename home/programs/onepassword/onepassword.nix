{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      _1password-gui
      _1password-cli
    ];
}
