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
#
# When the caller sets `_nut_marker` (see nut_run_ruby), the program's output is
# bracketed with that literal string. It is baked into the program as a literal
# — NOT read from ENV — because the remote runs rails through Spring, which does
# not forward per-invocation env vars into its pre-booted process. Framework boot
# logs (Datadog/Rails on staging) are written to stdout *before* the program's
# first line runs, so they land outside the markers and the runner's filter drops
# them — leaving only the summary.
nut_bundle_ruby() {
  local entry="$1"; shift
  typeset -gA _NUT_INLINED=()
  _nut_emit_argv_prelude "$@"
  if [[ -n "$_nut_marker" ]]; then
    print -r -- "\$stdout.sync = true"
    print -r -- "\$stdout.puts('${_nut_marker}')"
  fi
  _nut_inline_ruby "${_nut_ruby_dir}/${entry}"
  [[ -n "$_nut_marker" ]] && print -r -- "\$stdout.puts('${_nut_marker}')"
  unset _NUT_INLINED
}

# --- Flag parsing ---------------------------------------------------------

# Parse `--key value` and `--key=value` pairs into the global assoc array
# _nut_flags (reset on each call). Returns 1 on a stray non-flag argument.
# Entity handlers read the flags they care about and validate required ones.
_nut_parse_flags() {
  typeset -gA _nut_flags=()
  while (( $# )); do
    case "$1" in
      --*=*) local pair="${1#--}"; _nut_flags[${pair%%=*}]="${pair#*=}"; shift ;;
      --*)   local key="${1#--}"
             if (( $# >= 2 )); then _nut_flags[$key]="$2"; shift 2
             else _nut_flags[$key]=""; shift; fi ;;
      *) echo "nut: unexpected argument '$1' (use --flag value)"; return 1 ;;
    esac
  done
  return 0
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

  # Unique per-run marker, baked into the program as a literal (see
  # nut_bundle_ruby — env vars don't survive the remote's Spring preloader). The
  # awk filter keeps only the lines between the two markers, stripping the
  # framework log noise the remote writes to stdout (e.g. Datadog/Rails on
  # staging). `setopt pipefail` makes a real rails failure still set the exit
  # code (otherwise awk's success would mask it).
  local marker="___NUT_OUTPUT_${RANDOM}${RANDOM}___"
  local _nut_marker="$marker"   # dynamically scoped; read by nut_bundle_ruby
  local filter="awk -v m=${(q)marker} '\$0==m{f=!f;next} f'"

  local tmp; tmp="$(mktemp)"
  nut_bundle_ruby "$script" "$@" > "$tmp"

  local cmd
  if [[ "$mode" == "local" ]]; then
    cmd="setopt pipefail; ( cd ${(q)NUTRIUM_DIR} && SEED_SUMMARY_COLOR=${color} bin/rails runner - < ${(q)tmp} ) | ${filter}"
  else
    local remote="cd ${dir} && SEED_SUMMARY_COLOR=${color} RAILS_ENV=${renv} bin/rails runner -"
    cmd="setopt pipefail; ssh ${(q)host} ${(qq)remote} < ${(q)tmp} | ${filter}"
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

# --- Dispatchers ----------------------------------------------------------

# nut seed [--dry-run] [<target>] <entity> [args...]
nut_seed() {
  [[ "$1" == "--dry-run" ]] && { local NUT_DRY_RUN=1; shift; }

  local -a known=(professional secretary)
  local target entity
  if (( ${known[(Ie)$1]} )); then
    target="local"; entity="$1"; [[ $# -gt 0 ]] && shift
  else
    target="$1"; [[ $# -gt 0 ]] && shift
    entity="$1"; [[ $# -gt 0 ]] && shift
  fi

  case "$entity" in
    professional) _nut_seed_professional "$target" "$@" ;;
    secretary)    _nut_seed_secretary "$target" "$@" ;;
    "") echo "nut seed: missing entity. Known: ${(j:, :)known}"; return 1 ;;
    *)  echo "nut seed: unknown entity '${entity}'. Known: ${(j:, :)known}"; return 1 ;;
  esac
}

# <target> --country <PT|US> --email <e> --name <n> — all flags required.
_nut_seed_professional() {
  local target="$1"; shift
  _nut_parse_flags "$@" || return 1
  local country="${_nut_flags[country]:-}" email="${_nut_flags[email]:-}" name="${_nut_flags[name]:-}"
  [[ -z "$country" ]] && { echo "nut seed professional: --country is required (PT|US)"; return 1; }
  [[ -z "$email" ]]   && { echo "nut seed professional: --email is required"; return 1; }
  [[ -z "$name" ]]    && { echo "nut seed professional: --name is required"; return 1; }
  case "${country:u}" in
    PT|US) ;;
    *) echo "nut seed professional: unknown --country '${country}'. Known: PT, US"; return 1 ;;
  esac
  nut_run_ruby "$target" "create_professional.rb" "${country:u}" "$email" "$name"
}

# <target> --email <e> --name <n> [--professional <name>] [--workplace-scoped] [--requests N].
# --workplace-scoped is a bare boolean, so pull it out before the (value-only)
# flag parser sees it and swallows the following argument.
_nut_seed_secretary() {
  local target="$1"; shift
  local scoped=false
  local -a rest=()
  local a
  for a in "$@"; do
    if [[ "$a" == "--workplace-scoped" ]]; then scoped=true; else rest+=("$a"); fi
  done
  _nut_parse_flags "${rest[@]}" || return 1
  local email="${_nut_flags[email]:-}" name="${_nut_flags[name]:-}"
  local professional="${_nut_flags[professional]:-}" requests="${_nut_flags[requests]:-3}"
  [[ -z "$email" ]] && { echo "nut seed secretary: --email is required"; return 1; }
  [[ -z "$name" ]]  && { echo "nut seed secretary: --name is required"; return 1; }
  nut_run_ruby "$target" "create_secretary.rb" "$email" "$name" "$professional" "$scoped" "$requests"
}

# nut get [--dry-run] [<target>] <thing> [args...]
nut_get() {
  [[ "$1" == "--dry-run" ]] && { local NUT_DRY_RUN=1; shift; }

  local -a known=(otp secretaries)
  local target thing
  if (( ${known[(Ie)$1]} )); then
    target="local"; thing="$1"; [[ $# -gt 0 ]] && shift
  else
    target="$1"; [[ $# -gt 0 ]] && shift
    thing="$1"; [[ $# -gt 0 ]] && shift
  fi

  case "$thing" in
    otp)         _nut_get_otp "$target" "$@" ;;
    secretaries) _nut_get_secretaries "$target" "$@" ;;
    "") echo "nut get: missing thing. Known: ${(j:, :)known}"; return 1 ;;
    *)  echo "nut get: unknown thing '${thing}'. Known: ${(j:, :)known}"; return 1 ;;
  esac
}

# <target> [email] — default the email as the old get-otp did.
_nut_get_otp() {
  local target="$1"; shift
  local email="${1:-pedroribeiro@nutrium.com}"
  nut_run_ruby "$target" "get_otp.rb" "$email"
}

# <target> — read-only. Lists secretaries whose professional can exercise the
# appointment-requests feature (scheduling active + visible pending requests).
_nut_get_secretaries() {
  local target="$1"; shift
  nut_run_ruby "$target" "get_secretaries.rb"
}

# nut destroy [--dry-run] [<target>] <entity> [flags...]
nut_destroy() {
  [[ "$1" == "--dry-run" ]] && { local NUT_DRY_RUN=1; shift; }

  local -a known=(professional)
  local target entity
  if (( ${known[(Ie)$1]} )); then
    target="local"; entity="$1"; [[ $# -gt 0 ]] && shift
  else
    target="$1"; [[ $# -gt 0 ]] && shift
    entity="$1"; [[ $# -gt 0 ]] && shift
  fi

  case "$entity" in
    professional) _nut_destroy_professional "$target" "$@" ;;
    "") echo "nut destroy: missing entity. Known: ${(j:, :)known}"; return 1 ;;
    *)  echo "nut destroy: unknown entity '${entity}'. Known: ${(j:, :)known}"; return 1 ;;
  esac
}

# <target> --email <e> — email required. Hard-deletes the seed footprint.
_nut_destroy_professional() {
  local target="$1"; shift
  _nut_parse_flags "$@" || return 1
  local email="${_nut_flags[email]:-}"
  [[ -z "$email" ]] && { echo "nut destroy professional: --email is required"; return 1; }
  nut_run_ruby "$target" "destroy_professional.rb" "$email"
}
