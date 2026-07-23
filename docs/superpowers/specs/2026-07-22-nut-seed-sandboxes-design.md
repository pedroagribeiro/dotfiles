# `nut` seed/get grammar + sandbox execution — design

**Date:** 2026-07-22
**Status:** Approved (pilot scope)

## Problem

Today `nut` seeds data only against the **local** Nutrium environment. Each
command (`create-pt-professional`, `get-otp`, …) maps to a zsh function that
calls `execute_ruby_script_host`, which runs `cd $NUTRIUM_DIR && bin/rails
runner <script>.rb args` locally. The Ruby scripts share logic through
`require_relative "support/..."`.

Seeding a remote sandbox is manual:

```
ssh nutrium
cd /nutrium-<sandbox_name>
RAILS_ENV=staging rails console
# paste the commands to seed a professional
```

We want a first-class, idiomatic command surface that targets sandboxes:

```
nut seed <sandbox_name> professional PT
nut get  <sandbox_name> otp <email>
```

reusing the existing `ProfessionalFactory` logic.

## Hard constraints

- **Nothing is copied to the remote box.** No `scp`/`rsync`/`docker cp`, no
  files left behind. The program must stream in over the SSH channel, execute,
  and be gone.
- Reuse the existing Ruby seed logic (`ProfessionalFactory`, `SeedSummary`)
  verbatim — no duplication.

## Scope

**Pilot only.** Build the target-resolution + remote-execution framework and
ship two commands end-to-end: `seed professional` and `get otp`. Existing
`create-*` / `get-otp` commands keep working untouched; migrating them into the
new grammar happens later once the pattern is proven. DB/service verbs
(`reset-dbs`, `start-services`, `reindex-search`) stay as their own verbs — they
are inherently local and don't fit `seed`/`get`.

## Grammar & UX

```
nut seed [<target>] <entity> [args...]
nut get  [<target>] <thing>  [args...]
```

- `<target>` = a sandbox name, the literal `local`, or **omitted** → local.
- **Disambiguation rule:** entities/things are a known set. If the first token
  after the verb is a known entity (`professional`) / thing (`otp`), the target
  is `local`; otherwise that token is the target and we shift. (A sandbox named
  exactly `professional`/`otp` is not a realistic collision.)

Examples:

| Command | Runs |
|---|---|
| `nut seed professional PT` | local, PT professional |
| `nut seed my-sandbox professional PT` | remote sandbox, PT professional |
| `nut seed local professional US` | explicit local |
| `nut get otp pt-pro@nutrium.com` | local OTP lookup |
| `nut get my-sandbox otp pt-pro@nutrium.com` | remote OTP lookup |

`professional <COUNTRY>` keeps today's per-country defaults
(`pt-pro@nutrium.com` / "Ana Silva"; `us-pro@nutrium.com` / "John Smith").
Optional email/name args are a later addition.

## Architecture

Three building blocks in a new `aliases/nutrium/runner.zsh`, so both local and
remote runs go through one code path.

### a) Target resolver — `nut_resolve_target`

Parses the args after the verb, applies the disambiguation rule, and emits the
executor config:

- **local** → run in `$NUTRIUM_DIR`, no SSH.
- **sandbox** → `ssh $NUT_SSH_HOST`, `cd /nutrium-<sandbox>`,
  `RAILS_ENV=$NUT_RAILS_ENV`.

Defaults (overridable via env): `NUT_SSH_HOST=nutrium`, `NUT_RAILS_ENV=staging`.
Working dir pattern: `/nutrium-<sandbox>`.

### b) Ruby bundler — `nut_bundle_ruby <script.rb>`

Produces one self-contained program (written to a **local** temp file only):

1. **Inline dependencies.** Recursively resolve `require_relative "..."`
   relative to each file's directory, inlining each dependency exactly once
   (dedupe) and stripping the `require_relative` line. Dependency graph for the
   pilot:
   - `create_professional.rb` → `support/professional_factory` → `support/summary`
   - `get_otp.rb` → `support/summary`
2. **Inject args as a prelude.** Prepend `ARGV.replace([...])` where the array
   is **JSON-encoded locally** (a JSON string array is valid Ruby for our
   values). All dynamic data (country, email, name) therefore rides *inside* the
   piped program. **The SSH command line carries zero dynamic arguments**,
   which eliminates double-shell-quoting bugs across the local→ssh→remote shell
   layers.

### c) Runner — `nut_run_ruby <target-config> <script> [args...]`

Bundles to a local temp file, builds the command, hands it to the existing
`execute` helper (spinner + captured output), and cleans up the temp file:

- **local:** `cd $NUTRIUM_DIR && SEED_SUMMARY_COLOR=$c bin/rails runner - < $tmp`
- **remote:** `ssh $NUT_SSH_HOST "cd /nutrium-<sb> && SEED_SUMMARY_COLOR=$c RAILS_ENV=$NUT_RAILS_ENV bin/rails runner -" < $tmp`

`bin/rails runner -` reads the program from stdin. `SEED_SUMMARY_COLOR` is
forwarded (TTY detected before `execute` redirects stdout) so the boxed
`SeedSummary` output keeps its colors — same mechanism the current host runner
uses.

### Dispatchers & registries

`runner.zsh` also holds `nut_seed` / `nut_get` and the registries:

- seed entities: `professional → create_professional.rb`
- get things: `otp → get_otp.rb`

Adding a future entity = one registry line (+ a Ruby script if new).

## File changes

- **New** `aliases/nutrium/runner.zsh` — resolver, bundler, runner, registries,
  `nut_seed` / `nut_get`.
- **Edit** `aliases/nutrium.zsh` — add `seed)` / `get)` dispatch cases; update
  `_nut_help` (new SEED / GET section) and `_nut` completion.
- **Unchanged** — all Ruby scripts and `support/*`; `ProfessionalFactory` reused
  verbatim; existing `create-*` / `get-otp` commands.
- The legacy, currently-broken `execute_ruby_script` (docker) is left untouched.

## Safety & inspection

- **`--dry-run`** (or `NUT_DRY_RUN=1`): print the assembled command + bundled
  program instead of executing. Lets you inspect exactly what will hit a
  sandbox before trusting it; also the primary test seam.
- Unknown entity/thing → error listing the known ones.
- Sandbox existence is not pre-validated; ssh/rails errors surface through
  `execute`'s failure output (stderr + failed command).

## Error handling

- Missing `$NUTRIUM_DIR` for local runs → existing behavior.
- SSH auth/connection failure or wrong sandbox dir → non-zero exit captured and
  printed by `execute`.
- Ruby/Rails runtime errors → captured stderr printed by `execute`.

## Testing

The pure seams are the test targets:

- **Bundler:** given `create_professional.rb`, assert output contains no
  `require_relative`, each support file appears exactly once, and a valid
  `ARGV.replace([...])` prelude with the passed args.
- **Resolver:** given arg vectors, assert correct local-vs-remote decision and
  host/dir/env values (incl. env-var overrides).
- **Dry-run:** assert the composed command string for both a local and a
  sandbox target.
- **Manual E2E:** `nut seed local professional PT`, then a real
  `nut seed <sandbox> professional PT` and `nut get <sandbox> otp <email>`.

## Future (out of scope for the pilot)

- Migrate remaining seeds (`patient`, `questionaires`, `food-diaries`) and reads
  into the new grammar.
- Optional email/name args for `professional`.
- Portability for sharing with colleagues (avoid hardcoded ssh alias; document
  required `~/.ssh/config`) — tracked by the shareable-tooling goal.
