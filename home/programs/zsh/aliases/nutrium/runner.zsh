# Execution framework for the target-aware `nut seed` / `nut get` grammar.
#
#   nut seed [<target>] <entity> [args...]
#   nut get  [<target>] <thing>  [args...]
#
# <target> is a sandbox name, the literal `local`, or omitted (-> local).
# One Ruby program is built locally and streamed into `rails runner` over
# stdin — nothing is ever copied to the remote box.

# Directory holding the Ruby seed scripts and their support/ deps.
_nut_ruby_dir="${DOTFILES}/home/programs/zsh/aliases/nutrium/ruby"

# --- Ruby bundler ---------------------------------------------------------

# Emit `ARGV.replace([...])` with each argument as a Ruby single-quoted
# string. Pure zsh: the data rides inside the program, so the ssh command
# line stays static and free of quoting hazards.
_nut_emit_argv_prelude() {
  local out="ARGV.replace([" first=1 a esc
  for a in "$@"; do
    esc="${a//\\/\\\\}"    # escape backslashes first
    esc="${esc//\'/\'}"    # then single quotes
    if (( first )); then first=0; else out+=", "; fi
    out+="'${esc}'"
  done
  out+="])"
  print -r -- "$out"
}

# Recursively print a Ruby file with its `require_relative` deps inlined in
# place, each file emitted at most once. Dedupe state is the global
# _NUT_INLINED, reset by nut_bundle_ruby.
_nut_inline_ruby() {
  local file="$1"
  [[ -n "${_NUT_INLINED[$file]}" ]] && return
  _NUT_INLINED[$file]=1

  local dir="${file:h}" line target resolved
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ 'require_relative[[:space:]]+["'\'']([^"'\'']+)["'\'']' ]]; then
      target="${match[1]}"
      resolved="${dir}/${target}"
      [[ "$resolved" != *.rb ]] && resolved="${resolved}.rb"
      _nut_inline_ruby "$resolved"
    else
      print -r -- "$line"
    fi
  done < "$file"
}

# Build a self-contained Ruby program from an entry script (relative to
# _nut_ruby_dir) plus its args, printed to stdout.
nut_bundle_ruby() {
  local entry="$1"; shift
  typeset -gA _NUT_INLINED=()
  _nut_emit_argv_prelude "$@"
  _nut_inline_ruby "${_nut_ruby_dir}/${entry}"
  unset _NUT_INLINED
}

# --- Target resolution ----------------------------------------------------

# Map a target name to an executor config, printed as
#   <mode>|<ssh_host>|<remote_dir>|<rails_env>
# Local (empty or "local") -> "local|||".
nut_resolve_target() {
  local target="$1"
  if [[ -z "$target" || "$target" == "local" ]]; then
    print -r -- "local|||"
  else
    print -r -- "remote|${NUT_SSH_HOST:-nutrium}|/nutrium-${target}|${NUT_RAILS_ENV:-staging}"
  fi
}
