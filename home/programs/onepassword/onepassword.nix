{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ghostty flake is not packaged for Darwin
  home.packages = 
    with pkgs;
    [
      _1password-gui
      _1password-cli
    ];
}
