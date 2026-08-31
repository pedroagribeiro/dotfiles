{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ghostty flake is not packaged for Darwin
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux (
    with pkgs;
    [
      ghostty
    ]
  );

  xdg.configFile."ghostty/config" = mkSymlink "config";
  xdg.configFile."ghostty/keybindings" =
    if pkgs.stdenv.hostPlatform.isDarwin then mkSymlink "macos" else mkSymlink "linux";

  xdg.configFile."ghostty/themes/Day" = mkSymlink "themes/Day";
  xdg.configFile."ghostty/themes/Night" = mkSymlink "themes/Night";
  xdg.configFile."ghostty/themes/vscode-dark-2026" = mkSymlink "themes/vscode-dark-2026";
  xdg.configFile."ghostty/themes/vscode-light-2026" = mkSymlink "themes/vscode-light-2026";

  dconf.settings = lib.mkIf config.dotfiles.programs.gnome.enable {
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Terminal";
      command = "ghostty";
      binding = "<Super>Return";
    };
  };

}
