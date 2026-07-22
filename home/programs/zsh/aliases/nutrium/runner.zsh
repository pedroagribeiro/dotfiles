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

# --- Runner ---------------------------------------------------------------

# nut_run_ruby <target> <script.rb> [args...]
# Bundle the script locally and run it against the resolved target. Honors
# NUT_DRY_RUN: print the command + program instead of executing.
nut_run_ruby() {
  local target="$1" script="$2"; shift 2

  local resolved mode host dir renv
  resolved="$(nut_resolve_target "$target")"
  mode="${resolved%%|*}"; resolved="${resolved#*|}"
  host="${resolved%%|*}"; resolved="${resolved#*|}"
  dir="${resolved%%|*}";  resolved="${resolved#*|}"
  renv="${resolved}"

  # Detect the TTY here: `execute` redirects stdout, so the Ruby summary can't.
  local color=0; [[ -t 1 ]] && color=1

  local tmp; tmp="$(mktemp)"
  nut_bundle_ruby "$script" "$@" > "$tmp"

  local cmd
  if [[ "$mode" == "local" ]]; then
    cmd="( cd ${(q)NUTRIUM_DIR} && SEED_SUMMARY_COLOR=${color} bin/rails runner /dev/stdin < ${(q)tmp} )"
  else
    local remote="cd ${dir} && SEED_SUMMARY_COLOR=${color} RAILS_ENV=${renv} bin/rails runner /dev/stdin"
    cmd="ssh ${(q)host} ${(qq)remote} < ${(q)tmp}"
  fi

  if [[ -n "$NUT_DRY_RUN" ]]; then
    print -r -- "# target: ${mode}${host:+ (${host}:${dir}, RAILS_ENV=${renv})}"
    print -r -- "# command:"
    print -r -- "$cmd"
    print -r -- "# --- bundled program ---"
    cat "$tmp"
    rm -f "$tmp"
    return 0
  fi

  execute -o "nut ${mode} run: ${script}" "$cmd"
  local rc=$?
  rm -f "$tmp"
  return $rc
}
