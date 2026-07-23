#!/usr/bin/env zsh
# Run: zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh
emulate -L zsh

DOTFILES="$(cd "${0:A:h}" && git rev-parse --show-toplevel)"
export DOTFILES
: ${NUTRIUM_DIR:="$HOME/Code/healthium/nutrium"}

source "${DOTFILES}/home/programs/zsh/functions/helpers.zsh"
source "${DOTFILES}/home/programs/zsh/aliases/nutrium/runner.zsh"

typeset -g _tests=0 _fails=0

assert_contains() {   # <haystack> <needle> <msg>
  (( _tests++ ))
  if [[ "$1" == *"$2"* ]]; then print -r -- "  ok: $3"
  else (( _fails++ )); print -r -- "  FAIL: $3"; print -r -- "    expected to contain: $2"; fi
}
assert_not_contains() {   # <haystack> <needle> <msg>
  (( _tests++ ))
  if [[ "$1" != *"$2"* ]]; then print -r -- "  ok: $3"
  else (( _fails++ )); print -r -- "  FAIL: $3"; print -r -- "    expected NOT to contain: $2"; fi
}
assert_eq() {   # <actual> <expected> <msg>
  (( _tests++ ))
  if [[ "$1" == "$2" ]]; then print -r -- "  ok: $3"
  else (( _fails++ )); print -r -- "  FAIL: $3"; print -r -- "    expected: $2"; print -r -- "    actual:   $1"; fi
}
count_occurrences() {   # <haystack> <needle> -> prints integer
  local h="$1" n="$2" c=0
  while [[ "$h" == *"$n"* ]]; do (( c++ )); h="${h#*"$n"}"; done
  print -r -- "$c"
}

print -r -- "== bundler =="
prof="$(nut_bundle_ruby create_professional.rb PT)"
assert_not_contains "$prof" "require_relative" "professional bundle has no require_relative"
assert_contains "$prof" "ARGV.replace(['PT'])" "professional bundle has ARGV prelude"
assert_contains "$prof" "module ProfessionalFactory" "professional bundle inlines the factory"
assert_contains "$prof" "ProfessionalFactory.create" "professional bundle keeps the entry body"
assert_eq "$(count_occurrences "$prof" "module SeedSummary")" "1" "SeedSummary inlined exactly once"

otp="$(nut_bundle_ruby get_otp.rb foo@bar.com)"
assert_not_contains "$otp" "require_relative" "otp bundle has no require_relative"
assert_contains "$otp" "ARGV.replace(['foo@bar.com'])" "otp bundle has ARGV prelude"
assert_eq "$(count_occurrences "$otp" "module SeedSummary")" "1" "otp SeedSummary inlined once"
assert_not_contains "$prof" 'stdout.puts(' "bundle has no marker lines when _nut_marker unset"
prof_m="$(_nut_marker=___TESTMARK___ nut_bundle_ruby create_professional.rb PT)"
assert_contains "$prof_m" "\$stdout.puts('___TESTMARK___')" "bundle bakes the literal marker when set"
assert_eq "$(count_occurrences "$prof_m" "___TESTMARK___")" "2" "marker brackets output (start + end)"

destroy="$(nut_bundle_ruby destroy_professional.rb foo@bar.com)"
assert_not_contains "$destroy" "require_relative" "destroy bundle has no require_relative"
assert_contains "$destroy" "ARGV.replace(['foo@bar.com'])" "destroy bundle has ARGV prelude"
assert_contains "$destroy" "anonymize_attributes_and_relationships" "destroy bundle anonymizes the professional"
assert_eq "$(count_occurrences "$destroy" "module SeedSummary")" "1" "destroy SeedSummary inlined once"

esc="$(_nut_emit_argv_prelude "O'Brien" 'a\b')"
assert_eq "$esc" "ARGV.replace(['O\\'Brien', 'a\\\\b'])" "argv prelude escapes quotes and backslashes"

print -r -- "== resolver =="
assert_eq "$(nut_resolve_target "")"      "local|||"                          "empty target -> local"
assert_eq "$(nut_resolve_target local)"   "local|||"                          "literal local -> local"
assert_eq "$(nut_resolve_target my-sb)"   "remote|nutrium|/nutrium-my-sb|staging" "sandbox -> remote defaults"
assert_eq "$(NUT_SSH_HOST=box NUT_RAILS_ENV=production nut_resolve_target x)" \
          "remote|box|/nutrium-x|production" "env vars override host and rails env"

print -r -- "== runner (dry-run) =="
lrun="$(NUT_DRY_RUN=1 nut_run_ruby "" create_professional.rb PT)"
assert_contains "$lrun" "cd ${NUTRIUM_DIR}"       "local run cds into NUTRIUM_DIR"
assert_contains "$lrun" "bin/rails runner -" "local run uses rails runner on stdin"
assert_not_contains "$lrun" "ssh "                "local run does not ssh"
assert_contains "$lrun" "ARGV.replace(['PT'])"    "local run streams the bundled program"
assert_contains "$lrun" "stdout.puts('___NUT_OUTPUT" "local run bakes the literal marker into the program"
assert_contains "$lrun" "| awk"                   "local run filters output through awk"

rrun="$(NUT_DRY_RUN=1 nut_run_ruby my-sb get_otp.rb x@y.com)"
assert_contains "$rrun" "ssh "                    "remote run uses ssh"
assert_contains "$rrun" "/nutrium-my-sb"          "remote run targets the sandbox dir"
assert_contains "$rrun" "RAILS_ENV=staging"       "remote run sets RAILS_ENV"
assert_contains "$rrun" "bin/rails runner -" "remote run uses rails runner on stdin"
assert_contains "$rrun" "ARGV.replace(['x@y.com'])"  "remote run streams the bundled program"
assert_contains "$rrun" "stdout.puts('___NUT_OUTPUT" "remote run bakes the literal marker into the program"
assert_contains "$rrun" "| awk"                   "remote run filters output through awk"

print -r -- "== flag parser =="
_nut_parse_flags --country PT --email a@b.com --name "Ana Silva"
assert_eq "${_nut_flags[country]}" "PT"          "parses --key value"
assert_eq "${_nut_flags[email]}"   "a@b.com"     "parses another --key value"
assert_eq "${_nut_flags[name]}"    "Ana Silva"   "parses a value with spaces"
_nut_parse_flags --country=US --email=x@y.com
assert_eq "${_nut_flags[country]}" "US"          "parses --key=value"
assert_eq "${_nut_flags[email]}"   "x@y.com"     "parses another --key=value"
stray="$(_nut_parse_flags positional 2>&1)"
assert_contains "$stray" "unexpected argument 'positional'" "rejects stray non-flag arg"

print -r -- "== dispatchers (dry-run) =="
# Local professional: known entity first -> target local; flags required.
sp_local="$(nut_seed --dry-run professional --country PT --email ana@x.com --name 'Ana Silva')"
assert_not_contains "$sp_local" "ssh " "seed professional runs local"
assert_contains "$sp_local" "ARGV.replace(['PT', 'ana@x.com', 'Ana Silva'])" \
  "seed professional passes flag values"

# Remote professional: first token is the sandbox; country is upcased.
sp_remote="$(nut_seed --dry-run my-sb professional --country us --email j@x.com --name 'John Smith')"
assert_contains "$sp_remote" "/nutrium-my-sb" "seed <sandbox> professional targets sandbox"
assert_contains "$sp_remote" "ARGV.replace(['US', 'j@x.com', 'John Smith'])" \
  "seed professional upcases --country"

# Required-flag validation.
e_email="$(nut_seed professional --country PT --name x 2>&1)"
assert_contains "$e_email" "--email is required" "seed professional requires --email"
e_name="$(nut_seed professional --country PT --email a@b.com 2>&1)"
assert_contains "$e_name" "--name is required" "seed professional requires --name"
e_ctry="$(nut_seed professional --email a@b.com --name x 2>&1)"
assert_contains "$e_ctry" "--country is required" "seed professional requires --country"

# get otp: remote + explicit email.
g_remote="$(nut_get --dry-run my-sb otp a@b.com)"
assert_contains "$g_remote" "/nutrium-my-sb" "get <sandbox> otp targets sandbox"
assert_contains "$g_remote" "ARGV.replace(['a@b.com'])" "get otp passes the email"

# get otp: local default email when omitted.
g_default="$(nut_get --dry-run otp)"
assert_not_contains "$g_default" "ssh " "get otp with no target runs local"
assert_contains "$g_default" "ARGV.replace(['pedroribeiro@nutrium.com'])" \
  "get otp defaults the email"

# Errors.
e_entity="$(nut_seed nope-sb bogus 2>&1)"
assert_contains "$e_entity" "unknown entity 'bogus'" "unknown entity reported"

# destroy: dispatch, required flag, and dry-run command shape.
d_remote="$(nut_destroy --dry-run 12000 professional --email a@b.com)"
assert_contains "$d_remote" "/nutrium-12000"                "destroy targets the sandbox dir"
assert_contains "$d_remote" "anonymize_attributes_and_relationships" "destroy runs the anonymize script"
assert_contains "$d_remote" "ARGV.replace(['a@b.com'])"     "destroy passes the email"
d_local="$(nut_destroy --dry-run professional --email a@b.com)"
assert_not_contains "$d_local" "ssh " "destroy professional runs local when no target"
d_noemail="$(nut_destroy 12000 professional 2>&1)"
assert_contains "$d_noemail" "--email is required" "destroy professional requires --email"
d_unknown="$(nut_destroy 12000 bogus 2>&1)"
assert_contains "$d_unknown" "unknown entity 'bogus'" "destroy reports unknown entity"

# Injection safety: entity args must NEVER appear on the ssh command line.
payload=$'x\'; rm -rf / $(whoami) `id`'
inj_out="$(nut_seed --dry-run my-sb professional --country PT --email me@x.com --name "$payload")"
# The command header is everything before the bundled-program section.
inj_cmdline="${inj_out%%# --- bundled program ---*}"
assert_not_contains "$inj_cmdline" "rm -rf" "injection payload stays off the ssh command line"
assert_contains "$inj_out" "rm -rf" "injection payload rides inside the bundled program"

print -r -- ""
if (( _fails )); then print -r -- "FAILED: ${_fails}/${_tests}"; exit 1
else print -r -- "PASSED: ${_tests}/${_tests}"; exit 0; fi
