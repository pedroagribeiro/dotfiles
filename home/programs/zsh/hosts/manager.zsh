# Per-account GitHub CLI: nutrium token under the nutrium tree, personal
# token everywhere else. Mirrors the folder-based git ssh-key split.
gh() {
  local token_file=/root/.config/gh/token-personal
  case "$PWD" in
    /root/Code/healthium/nutrium|/root/Code/healthium/nutrium/*)
      token_file=/root/.config/gh/token-nutrium
      ;;
  esac
  if [ -r "$token_file" ]; then
    GH_TOKEN="$(cat "$token_file")" command gh "$@"
  else
    command gh "$@"
  fi
}
