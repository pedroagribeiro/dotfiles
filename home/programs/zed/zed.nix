{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    zed-editor
  ];

  xdg.configFile."zed/settings.json" = mkSymlink "settings.json";
  xdg.configFile."zed/keymap.json" = mkSymlink "keymap.json";
  xdg.configFile."zed/themes/vscode-2026.json" = mkSymlink "themes/vscode-2026.json";
}
