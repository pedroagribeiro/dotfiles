{
  config,
  lib,
  pkgs,
  mkSymlink,
  username,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    claude-code
  ];

  # ── Symlinked Config Files ───────────────────────────────────────────
  # pedroribeiro (Darwin) uses a settings file with `apiKeyHelper` set;
  # every other user shares the base settings.json.
  home.file.".claude/settings.json" = mkSymlink (
    if username == "pedroribeiro" then "settings.healthium.json" else "settings.json"
  );
  home.file.".claude/skills" = mkSymlink "skills";
  home.file.".claude/statusline.sh" = mkSymlink "statusline.sh";
}
