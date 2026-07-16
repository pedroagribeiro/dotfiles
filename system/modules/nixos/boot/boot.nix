{
  config,
  lib,
  pkgs,
  onHost,
  ...
}:
lib.mkMerge [
  {
    boot.plymouth.enable = true;
  }
  (onHost "thinkpad" {
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;
  })
]
