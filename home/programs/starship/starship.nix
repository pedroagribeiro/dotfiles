{
  pkgs,
  mkSymlink,
  ...
}:
{
  home.packages = with pkgs; [
    starship
  ];

  # Symlinked rather than copied into the store, so edits to starship.toml show
  # up in the next shell without a rebuild.
  xdg.configFile."starship.toml" = mkSymlink "starship.toml";
}
