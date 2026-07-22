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

esc="$(_nut_emit_argv_prelude "O'Brien" 'a\b')"
assert_eq "$esc" "ARGV.replace(['O\\'Brien', 'a\\\\b'])" "argv prelude escapes quotes and backslashes"

print -r -- ""
if (( _fails )); then print -r -- "FAILED: ${_fails}/${_tests}"; exit 1
else print -r -- "PASSED: ${_tests}/${_tests}"; exit 0; fi
