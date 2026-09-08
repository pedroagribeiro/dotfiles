{
  config,
  lib,
  pkgs,
  mkSymlink,
  username,
  hostname,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    claude-code
  ];

  # ── Symlinked Config Files ───────────────────────────────────────────
  # The manager box and pedroribeiro (Darwin) each use a settings file with
  # `apiKeyHelper` set; every other user shares the base settings.json.
  home.file.".claude/settings.json" = mkSymlink (
    if hostname == "manager" then
      "settings.remote.json"
    else if username == "pedroribeiro" then
      "settings.healthium.json"
    else
      "settings.json"
  );
  home.file.".claude/CLAUDE.md" = mkSymlink "CLAUDE.md";
  home.file.".claude/skills" = mkSymlink "skills";
  home.file.".claude/statusline.sh" = mkSymlink "statusline.sh";
}
