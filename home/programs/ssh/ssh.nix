{
  config,
  lib,
  pkgs,
  hostname,
  mkSymlink,
  ...
}:
{
  # On the headless manager box use the system (Ubuntu) ssh: nix's openssh is
  # built without GSSAPI and warns on Ubuntu's system ssh_config.
  home.packages = lib.optionals (hostname != "manager") (
    with pkgs;
    [
      openssh
    ]
  );

  home.file = {
    ".ssh/config" = mkSymlink "config";
    ".ssh/platform.ini" =
      if pkgs.stdenv.hostPlatform.isDarwin then
        mkSymlink "platforms/macos"
      else if hostname == "manager" then
        mkSymlink "platforms/headless"
      else
        mkSymlink "platforms/linux";
    ".ssh/hosts/current.ini" = mkSymlink "hosts/${hostname}.ini";
    ".ssh/profiles/personal.ini" = mkSymlink "profiles/personal.ini";
    ".ssh/profiles/nutrium.ini" = mkSymlink "profiles/nutrium.ini";
  };
}
