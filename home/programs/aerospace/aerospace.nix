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

  # Linked as the TEMPLATE, not as the config AeroSpace reads. omamac renders
  # aerospace.toml beside it, substituting the values marked `# omamac:gaps`.
  #
  # AeroSpace can only change gaps by editing its config — the CLI is read-only
  # and there is no include mechanism — and this file is version-controlled, so
  # writing generated values here would put them in git. Rendering keeps the
  # declarative source tracked and the generated output machine-local.
  #
  # The render is re-run on activation by the omamac module, so editing this
  # file and rebuilding still takes effect.
  xdg.configFile."aerospace/aerospace.template.toml" = mkSymlink "aerospace.toml";
}
