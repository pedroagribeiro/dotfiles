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
assert_contains "$prof" 'ENV["NUT_OUTPUT_MARKER"]' "bundle brackets output with the run marker"

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
assert_contains "$lrun" "bin/rails runner /dev/stdin" "local run uses rails runner on stdin"
assert_not_contains "$lrun" "ssh "                "local run does not ssh"
assert_contains "$lrun" "ARGV.replace(['PT'])"    "local run streams the bundled program"
assert_contains "$lrun" "NUT_OUTPUT_MARKER="      "local run sets the output marker"
assert_contains "$lrun" "| awk"                   "local run filters output through awk"

rrun="$(NUT_DRY_RUN=1 nut_run_ruby my-sb get_otp.rb x@y.com)"
assert_contains "$rrun" "ssh "                    "remote run uses ssh"
assert_contains "$rrun" "/nutrium-my-sb"          "remote run targets the sandbox dir"
assert_contains "$rrun" "RAILS_ENV=staging"       "remote run sets RAILS_ENV"
assert_contains "$rrun" "bin/rails runner /dev/stdin" "remote run uses rails runner on stdin"
assert_contains "$rrun" "ARGV.replace(['x@y.com'])"  "remote run streams the bundled program"
assert_contains "$rrun" "NUT_OUTPUT_MARKER="      "remote run sets the output marker"
assert_contains "$rrun" "| awk"                   "remote run filters output through awk"

print -r -- "== dispatchers (dry-run) =="
# Local professional: known entity first token -> target is local; PT defaults applied.
sp_local="$(nut_seed --dry-run professional PT)"
assert_not_contains "$sp_local" "ssh " "seed professional PT runs local"
assert_contains "$sp_local" "ARGV.replace(['PT', 'pt-pro@nutrium.com', 'Ana Silva'])" \
  "seed professional PT applies PT defaults"

# Remote professional: first token is the sandbox; US defaults applied.
sp_remote="$(nut_seed --dry-run my-sb professional US)"
assert_contains "$sp_remote" "/nutrium-my-sb" "seed <sandbox> professional targets sandbox"
assert_contains "$sp_remote" "ARGV.replace(['US', 'us-pro@nutrium.com', 'John Smith'])" \
  "seed professional US applies US defaults"

# Explicit email/name override the defaults.
sp_over="$(nut_seed --dry-run professional PT me@x.com 'Me Myself')"
assert_contains "$sp_over" "ARGV.replace(['PT', 'me@x.com', 'Me Myself'])" \
  "explicit email/name override defaults"

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
e_country="$(nut_seed professional 2>&1)"
assert_contains "$e_country" "missing country" "missing country reported"

# Injection safety: entity args must NEVER appear on the ssh command line.
payload=$'x\'; rm -rf / $(whoami) `id`'
inj_out="$(nut_seed --dry-run my-sb professional PT me@x.com "$payload")"
# The command header is everything before the bundled-program section.
inj_cmdline="${inj_out%%# --- bundled program ---*}"
assert_not_contains "$inj_cmdline" "rm -rf" "injection payload stays off the ssh command line"
assert_contains "$inj_out" "rm -rf" "injection payload rides inside the bundled program"

print -r -- ""
if (( _fails )); then print -r -- "FAILED: ${_fails}/${_tests}"; exit 1
else print -r -- "PASSED: ${_tests}/${_tests}"; exit 0; fi
