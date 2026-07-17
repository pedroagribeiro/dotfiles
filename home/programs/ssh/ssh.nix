{
  config,
  lib,
  pkgs,
  hostname,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    openssh
  ];

  home.file = {
    ".ssh/config" = mkSymlink "config";
    ".ssh/platform.ini" =
      if pkgs.stdenv.hostPlatform.isDarwin then mkSymlink "platforms/macos"
      else mkSymlink "platforms/linux";
    ".ssh/hosts/current.ini" = mkSymlink "hosts/${hostname}.ini";
    ".ssh/profiles/personal.ini" = mkSymlink "profiles/personal.ini";
    ".ssh/profiles/nutrium.ini" = mkSymlink "profiles/nutrium.ini";
  };
}
