# `nut` seed/get grammar + sandbox execution — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a target-aware `nut seed [<target>] <entity>` / `nut get [<target>] <thing>` command grammar that runs the existing Ruby seed logic against local **or** remote sandboxes over SSH, without ever copying files to the remote.

**Architecture:** A new `runner.zsh` builds one self-contained Ruby program locally (inlining `require_relative` deps and injecting args as a Ruby `ARGV.replace([...])` prelude), writes it to a local temp file, and streams it into `bin/rails runner /dev/stdin` — directly for local, or over `ssh` for a sandbox. The SSH command line carries no dynamic data, so there is no cross-shell quoting hazard.

**Tech Stack:** zsh (functions + completion), Ruby (`rails runner`, reused `ProfessionalFactory`/`SeedSummary`), the existing `execute` spinner helper.

## Global Constraints

- **Never copy files to the remote.** No scp/rsync/docker cp. The program streams over stdin only. (Verbatim from spec.)
- **Reuse existing Ruby verbatim.** No changes to any file under `home/programs/zsh/aliases/nutrium/ruby/`. Per-country default email/name stay in the zsh layer (where they already live today).
- **No dependency on a system `ruby`/`jq`.** The bare `ruby` on this machine is broken (missing libgmp); the bundler is pure zsh.
- **Pilot scope only:** ship `seed professional` + `get otp`; leave all existing `create-*`/`get-otp` commands and DB/service verbs untouched.
- **Remote defaults (overridable via env):** `NUT_SSH_HOST=nutrium`, `NUT_RAILS_ENV=staging`, dir pattern `/nutrium-<sandbox>`.
- **Sourced on shell startup:** `runner.zsh` must always be syntactically valid and side-effect-free at source time (only function defs + one `_nut_ruby_dir` assignment). A broken file breaks the user's shell.

## File Structure

- **Create** `home/programs/zsh/aliases/nutrium/runner.zsh` — the whole framework: bundler, resolver, runner, dispatchers. Auto-sourced by the existing `for helper in .../nutrium/*.zsh` loop in `nutrium.zsh`.
- **Create** `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh` — self-contained zsh assertion script. Under `tests/` so the non-recursive `nutrium/*.zsh` glob never sources it.
- **Modify** `home/programs/zsh/aliases/nutrium.zsh` — add `seed)`/`get)` dispatch cases; extend `_nut_help` and `_nut` completion.
- **Unchanged** — everything under `nutrium/ruby/`; existing command functions in `ruby_scripts.zsh`.

---

### Task 1: Test harness + Ruby bundler

**Files:**
- Create: `home/programs/zsh/aliases/nutrium/runner.zsh`
- Test: `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `_nut_ruby_dir` — absolute path to the Ruby scripts dir.
  - `_nut_emit_argv_prelude [args...]` → prints one line `ARGV.replace(['a', 'b'])` with each arg escaped as a Ruby single-quoted string.
  - `_nut_inline_ruby <abs_file>` → prints the file with `require_relative` deps inlined in place, each file at most once (dedupe via global `_NUT_INLINED`).
  - `nut_bundle_ruby <entry_rel_to_ruby_dir> [args...]` → prints a self-contained Ruby program (ARGV prelude first, then inlined code) to stdout.

- [ ] **Step 1: Write the test harness + failing bundler tests**

Create `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`:

```zsh
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`
Expected: FAIL — sourcing errors / `nut_bundle_ruby: command not found` because `runner.zsh` does not exist yet.

- [ ] **Step 3: Create `runner.zsh` with the bundler**

Create `home/programs/zsh/aliases/nutrium/runner.zsh`:

```zsh
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
    esc="${esc//\'/\\\'}"  # then single quotes
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`
Expected: PASS — `PASSED: 9/9`.

- [ ] **Step 5: Syntax-check the sourced file**

Run: `zsh -n home/programs/zsh/aliases/nutrium/runner.zsh && echo OK`
Expected: `OK` (no output from `-n` means valid syntax).

- [ ] **Step 6: Commit**

```bash
git add home/programs/zsh/aliases/nutrium/runner.zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh
git commit -m "feat(nut): add self-contained ruby bundler for seed/get framework"
```

---

### Task 2: Target resolver

**Files:**
- Modify: `home/programs/zsh/aliases/nutrium/runner.zsh` (append)
- Test: `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh` (append)

**Interfaces:**
- Consumes: env `NUT_SSH_HOST`, `NUT_RAILS_ENV`.
- Produces: `nut_resolve_target <target>` → prints `<mode>|<ssh_host>|<remote_dir>|<rails_env>`. Local target (empty or `local`) → `local|||`. Sandbox `x` → `remote|nutrium|/nutrium-x|staging` (with env overrides applied).

- [ ] **Step 1: Write the failing resolver tests**

Append to `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`, immediately before the final results block (`print -r -- ""` … `PASSED`):

```zsh
print -r -- "== resolver =="
assert_eq "$(nut_resolve_target "")"      "local|||"                          "empty target -> local"
assert_eq "$(nut_resolve_target local)"   "local|||"                          "literal local -> local"
assert_eq "$(nut_resolve_target my-sb)"   "remote|nutrium|/nutrium-my-sb|staging" "sandbox -> remote defaults"
assert_eq "$(NUT_SSH_HOST=box NUT_RAILS_ENV=production nut_resolve_target x)" \
          "remote|box|/nutrium-x|production" "env vars override host and rails env"
```

- [ ] **Step 2: Run the tests to verify the new ones fail**

Run: `zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`
Expected: FAIL — `nut_resolve_target: command not found` (4 new failures); Task 1 tests still pass.

- [ ] **Step 3: Append the resolver to `runner.zsh`**

Append to `home/programs/zsh/aliases/nutrium/runner.zsh`:

```zsh
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`
Expected: PASS — `PASSED: 13/13`.

- [ ] **Step 5: Commit**

```bash
git add home/programs/zsh/aliases/nutrium/runner.zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh
git commit -m "feat(nut): resolve seed/get targets to local or ssh sandbox config"
```

---

### Task 3: Runner with dry-run

**Files:**
- Modify: `home/programs/zsh/aliases/nutrium/runner.zsh` (append)
- Test: `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh` (append)

**Interfaces:**
- Consumes: `nut_bundle_ruby`, `nut_resolve_target`, `execute` (from `functions/helpers.zsh`), env `NUTRIUM_DIR`, `NUT_DRY_RUN`.
- Produces: `nut_run_ruby <target> <script.rb> [args...]`. When `NUT_DRY_RUN` is non-empty, prints the composed command and the bundled program and returns 0 without executing; otherwise runs via `execute` and cleans up its temp file.

- [ ] **Step 1: Write the failing runner (dry-run) tests**

Append to `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`, before the final results block:

```zsh
print -r -- "== runner (dry-run) =="
lrun="$(NUT_DRY_RUN=1 nut_run_ruby "" create_professional.rb PT)"
assert_contains "$lrun" "cd ${NUTRIUM_DIR}"       "local run cds into NUTRIUM_DIR"
assert_contains "$lrun" "bin/rails runner /dev/stdin" "local run uses rails runner on stdin"
assert_not_contains "$lrun" "ssh "                "local run does not ssh"
assert_contains "$lrun" "ARGV.replace(['PT'])"    "local run streams the bundled program"

rrun="$(NUT_DRY_RUN=1 nut_run_ruby my-sb get_otp.rb x@y.com)"
assert_contains "$rrun" "ssh "                    "remote run uses ssh"
assert_contains "$rrun" "/nutrium-my-sb"          "remote run targets the sandbox dir"
assert_contains "$rrun" "RAILS_ENV=staging"       "remote run sets RAILS_ENV"
assert_contains "$rrun" "bin/rails runner /dev/stdin" "remote run uses rails runner on stdin"
assert_contains "$rrun" "ARGV.replace(['x@y.com'])"  "remote run streams the bundled program"
```

- [ ] **Step 2: Run the tests to verify the new ones fail**

Run: `zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`
Expected: FAIL — `nut_run_ruby: command not found` (9 new failures); earlier tests still pass.

- [ ] **Step 3: Append the runner to `runner.zsh`**

Append to `home/programs/zsh/aliases/nutrium/runner.zsh`:

```zsh
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
    cmd="ssh ${(q)host} ${(q)remote} < ${(q)tmp}"
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
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`
Expected: PASS — `PASSED: 22/22`.

- [ ] **Step 5: Syntax-check**

Run: `zsh -n home/programs/zsh/aliases/nutrium/runner.zsh && echo OK`
Expected: `OK`.

- [ ] **Step 6: Commit**

```bash
git add home/programs/zsh/aliases/nutrium/runner.zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh
git commit -m "feat(nut): run bundled ruby locally or over ssh with dry-run"
```

---

### Task 4: Dispatchers, wiring, help & completion

**Files:**
- Modify: `home/programs/zsh/aliases/nutrium/runner.zsh` (append)
- Modify: `home/programs/zsh/aliases/nutrium.zsh` (dispatch cases, help, completion)
- Test: `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh` (append)

**Interfaces:**
- Consumes: `nut_run_ruby`.
- Produces:
  - `nut_seed [--dry-run] [<target>] <entity> [args...]` — entity `professional <COUNTRY> [email] [name]`.
  - `nut_get [--dry-run] [<target>] <thing> [args...]` — thing `otp [email]`.
  - `_nut_seed_professional <target> <COUNTRY> [email] [name]` and `_nut_get_otp <target> [email]` — apply per-country / default values, then call `nut_run_ruby`.

- [ ] **Step 1: Write the failing dispatcher tests**

Append to `home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`, before the final results block:

```zsh
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
```

- [ ] **Step 2: Run the tests to verify the new ones fail**

Run: `zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`
Expected: FAIL — `nut_seed: command not found` (new failures); earlier tests still pass.

- [ ] **Step 3: Append the dispatchers to `runner.zsh`**

Append to `home/programs/zsh/aliases/nutrium/runner.zsh`:

```zsh
# --- Dispatchers ----------------------------------------------------------

# nut seed [--dry-run] [<target>] <entity> [args...]
nut_seed() {
  [[ "$1" == "--dry-run" ]] && { local NUT_DRY_RUN=1; shift; }

  local known="professional"
  local target entity
  if [[ " $known " == *" ${1} "* ]]; then
    target="local"; entity="$1"; [[ $# -gt 0 ]] && shift
  else
    target="$1"; [[ $# -gt 0 ]] && shift
    entity="$1"; [[ $# -gt 0 ]] && shift
  fi

  case "$entity" in
    professional) _nut_seed_professional "$target" "$@" ;;
    "") echo "nut seed: missing entity. Known: ${known}"; return 1 ;;
    *)  echo "nut seed: unknown entity '${entity}'. Known: ${known}"; return 1 ;;
  esac
}

# <target> <COUNTRY> [email] [name] — apply per-country defaults then run.
_nut_seed_professional() {
  local target="$1"; shift
  local country="${1:-}" email name
  case "${country:u}" in
    PT) email="pt-pro@nutrium.com"; name="Ana Silva" ;;
    US) email="us-pro@nutrium.com"; name="John Smith" ;;
    "") echo "nut seed professional: missing country. Known: PT, US"; return 1 ;;
    *)  echo "nut seed professional: unknown country '${country}'. Known: PT, US"; return 1 ;;
  esac
  [[ -n "${2:-}" ]] && email="$2"
  [[ -n "${3:-}" ]] && name="$3"
  nut_run_ruby "$target" "create_professional.rb" "$country" "$email" "$name"
}

# nut get [--dry-run] [<target>] <thing> [args...]
nut_get() {
  [[ "$1" == "--dry-run" ]] && { local NUT_DRY_RUN=1; shift; }

  local known="otp"
  local target thing
  if [[ " $known " == *" ${1} "* ]]; then
    target="local"; thing="$1"; [[ $# -gt 0 ]] && shift
  else
    target="$1"; [[ $# -gt 0 ]] && shift
    thing="$1"; [[ $# -gt 0 ]] && shift
  fi

  case "$thing" in
    otp) _nut_get_otp "$target" "$@" ;;
    "") echo "nut get: missing thing. Known: ${known}"; return 1 ;;
    *)  echo "nut get: unknown thing '${thing}'. Known: ${known}"; return 1 ;;
  esac
}

# <target> [email] — default the email as the old get-otp did.
_nut_get_otp() {
  local target="$1"; shift
  local email="${1:-pedroribeiro@nutrium.com}"
  nut_run_ruby "$target" "get_otp.rb" "$email"
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh`
Expected: PASS — `PASSED: 32/32`.

- [ ] **Step 5: Wire `seed`/`get` into the `nut` dispatcher**

In `home/programs/zsh/aliases/nutrium.zsh`, in the `case "$cmd" in` block, add two cases after the `get-otp)` line (line ~28):

```zsh
    get-otp)                get_otp "$@" ;;
    seed)                   nut_seed "$@" ;;
    get)                    nut_get "$@" ;;
```

- [ ] **Step 6: Document `seed`/`get` in `_nut_help`**

In `home/programs/zsh/aliases/nutrium.zsh`, inside the `_nut_help` heredoc, add a new section between the `SEED DATA` block and the `UTILITIES` block (after the `create-pt-professional` description, before `${b}UTILITIES${r}`):

```zsh
${b}SANDBOX SEED / GET${r} ${d}(target-aware; omit <target> for local)${r}
  ${c}seed${r} ${d}[<target>] professional <PT|US> [email] [name]${r}
      Seed a professional locally or on a sandbox. e.g. \`nut seed my-sandbox professional PT\`.
  ${c}get${r} ${d}[<target>] otp [email]${r}
      Print the current 2FA/OTP for an account locally or on a sandbox.
  ${d}Add --dry-run right after seed/get to print the command + program instead of running it.${r}

```

- [ ] **Step 7: Add `seed`/`get` to tab completion**

In `home/programs/zsh/aliases/nutrium.zsh`, in the `_nut` function's `subcommands` array, add after the `get-otp` entry:

```zsh
    'get-otp:Show the current 2FA/OTP code for an account'
    'seed:Seed an entity locally or on a sandbox'
    'get:Read a value locally or from a sandbox'
```

- [ ] **Step 8: Verify the whole file sources cleanly and dispatch works**

Run:
```bash
zsh -n home/programs/zsh/aliases/nutrium.zsh && zsh -n home/programs/zsh/aliases/nutrium/runner.zsh && echo SYNTAX_OK
DOTFILES="$(git rev-parse --show-toplevel)" zsh -ic 'nut seed --dry-run my-sandbox professional PT | head -3'
```
Expected: `SYNTAX_OK`, then a dry-run header showing `# target: remote (nutrium:/nutrium-my-sandbox, RAILS_ENV=staging)` and the `ssh` command line.

- [ ] **Step 9: Commit**

```bash
git add home/programs/zsh/aliases/nutrium.zsh home/programs/zsh/aliases/nutrium/runner.zsh home/programs/zsh/aliases/nutrium/tests/runner_test.zsh
git commit -m "feat(nut): add seed/get sandbox commands with help and completion"
```

---

## Manual end-to-end verification (after Task 4)

Not automated (needs a live repo + sandbox). Run in a fresh shell:

1. `nut seed --dry-run professional PT` — inspect the bundled program; confirm no `require_relative`, correct ARGV.
2. `nut seed local professional PT` — confirm the `SeedSummary` box prints and the professional is created/reused locally.
3. `nut get otp pt-pro@nutrium.com` — confirm the OTP box prints locally.
4. `nut seed <real-sandbox> professional PT` — confirm creation on the sandbox.
5. `nut get <real-sandbox> otp pt-pro@nutrium.com` — confirm OTP from the sandbox.

---

## Self-Review

**Spec coverage:**
- Grammar `seed`/`get` with optional target + disambiguation → Task 4 (`nut_seed`/`nut_get`) + Task 2 (resolver). ✓
- No files copied to remote; stream over stdin → Task 1 (bundler) + Task 3 (`/dev/stdin` via ssh). ✓
- Reuse `ProfessionalFactory`/`SeedSummary` verbatim → bundler inlines them; no Ruby edits. ✓
- Args injected inside the program, static ssh command line → Task 1 prelude + Task 3 runner. ✓
- Local default when target omitted → resolver + dispatcher disambiguation. ✓
- Env overrides `NUT_SSH_HOST`/`NUT_RAILS_ENV`, dir `/nutrium-<sb>`, `RAILS_ENV=staging` → Task 2. ✓
- Color forwarding via `SEED_SUMMARY_COLOR` → Task 3. ✓
- `--dry-run`/`NUT_DRY_RUN` inspection → Task 3 + Task 4. ✓
- Unknown entity/thing errors → Task 4. ✓
- Help + completion → Task 4 steps 6–7. ✓
- Pilot scope, existing commands untouched → only additive edits to `nutrium.zsh`; `ruby_scripts.zsh` and `ruby/` unchanged. ✓
- Testing seams (bundler, resolver, dry-run, dispatchers) → Tasks 1–4 tests. ✓

**Placeholder scan:** No TBD/TODO; every code and command step is complete.

**Type/name consistency:** `nut_bundle_ruby`, `nut_resolve_target`, `nut_run_ruby`, `nut_seed`, `nut_get`, `_nut_seed_professional`, `_nut_get_otp`, `_nut_ruby_dir`, `_NUT_INLINED`, `NUT_DRY_RUN`, `NUT_SSH_HOST`, `NUT_RAILS_ENV` used consistently across tasks. Resolver output format `<mode>|<host>|<dir>|<env>` is parsed the same way in Task 3. Test counts are cumulative (9 → 13 → 22 → 32).
