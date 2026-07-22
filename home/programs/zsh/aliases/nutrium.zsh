: ${NUTRIUM_DIR:="$HOME/Code/healthium/nutrium"}

for helper in "$DOTFILES"/home/programs/zsh/aliases/nutrium/*.zsh; do
  source "$helper"
done

alias hum='cd ~/Code/healthium'

# `nut` is the single entry point for project tooling. With no arguments it just
# jumps to the repo (as it always did); with a subcommand it dispatches to the
# underlying function. This replaces the old per-command aliases so adding a
# command means editing one place (this case) instead of three.
nut() {
  if [[ $# -eq 0 ]]; then
    cd "$NUTRIUM_DIR"
    return
  fi

  local cmd="$1"
  shift

  case "$cmd" in
    create-patient)         create_patient "$@" ;;
    create-questionaires)   create_questionaires "$@" ;;
    create-food-diaries)    create_food_diaries_for_patient "$@" ;;
    create-us-professional) create_us_professional "$@" ;;
    create-pt-professional) create_pt_professional "$@" ;;
    get-otp)                get_otp "$@" ;;
    seed)                   nut_seed "$@" ;;
    get)                    nut_get "$@" ;;
    # DB / service commands assume the repo as CWD, so run them rooted there.
    reset-dbs)              ( cd "$NUTRIUM_DIR" && reset_nutrium_databases "$@" ) ;;
    reset-dbs-docker)       ( cd "$NUTRIUM_DIR" && reset_nutrium_databases_docker "$@" ) ;;
    start-services)         ( cd "$NUTRIUM_DIR" && start_nutrium_services "$@" ) ;;
    reindex-search)         ( cd "$NUTRIUM_DIR" && reindex_nutrium_search "$@" ) ;;
    help|-h|--help)         _nut_help ;;
    *)
      echo "nut: unknown command '$cmd'"
      _nut_help
      return 1
      ;;
  esac
}

_nut_help() {
  # Color only when writing to a terminal, matching the seed summaries.
  local b='' d='' c='' g='' r=''
  if [[ -t 1 ]]; then
    b=$'\e[1m'      # bold        — section headers
    d=$'\e[2m'      # dim         — argument shapes, tips
    c=$'\e[36m'     # cyan        — command names
    g=$'\e[1;36m'   # bold cyan   — title
    r=$'\e[0m'
  fi

  cat <<EOF
${g}nut${r} — Nutrium project helpers

${b}USAGE${r}
  ${c}nut${r}                          ${d}cd to the nutrium repo${r}
  ${c}nut${r} <command> [args...]

${b}SEED DATA${r}
  ${c}create-patient${r} ${d}<email> <company> [professional]${r}
      Create a personalized patient. Idempotent — reuses an existing account.
  ${c}create-questionaires${r}
      Seed questionary templates from the repo YAML (skips ones already present).
  ${c}create-food-diaries${r} ${d}<email> <count> <filled>${r}
      Ensure <count> recent daily food diaries exist. Idempotent per day.
  ${c}create-us-professional${r} ${d}<email> <name>${r}
      Create a fully bootstrapped US professional (account, 2FA, seller, patient).
  ${c}create-pt-professional${r} ${d}<email> <name>${r}
      Create a fully bootstrapped PT professional (account, 2FA, seller, patient).

${b}SANDBOX SEED / GET${r} ${d}(target-aware; omit <target> for local)${r}
  ${c}seed${r} ${d}[<target>] professional <PT|US> [email] [name]${r}
      Seed a professional locally or on a sandbox. e.g. \`nut seed my-sandbox professional PT\`.
  ${c}get${r} ${d}[<target>] otp [email]${r}
      Print the current 2FA/OTP for an account locally or on a sandbox.
  ${d}Add --dry-run right after seed/get to print the command + program instead of running it.${r}

${b}UTILITIES${r}
  ${c}get-otp${r} ${d}<email>${r}
      Print the current (time-based) 2FA / OTP code for an account.

${b}DATABASE / SERVICES${r}
  ${c}reset-dbs${r} ${d}[--reindex|-r]${r}
      Reset dev + test DBs from the latest backup; -r also reindexes Elasticsearch.
  ${c}reset-dbs-docker${r}
      Same reset flow, for the dockerized setup.
  ${c}start-services${r}
      Start the backing services: postgres, redis, elasticsearch.
  ${c}reindex-search${r}
      Full Elasticsearch (Searchkick) reindex (~6.5 min).

${b}OTHER${r}
  ${c}help${r}                         show this message

${d}Tip: pass --help to a seed command for its own defaults,
     e.g. \`nut create-patient --help\`.${r}
EOF
}

# Tab-completion for the subcommands.
_nut() {
  local -a subcommands
  subcommands=(
    'create-patient:Create a personalized patient'
    'create-questionaires:Seed questionary templates'
    'create-food-diaries:Create food diaries for a patient'
    'create-us-professional:Create a US professional'
    'create-pt-professional:Create a PT professional'
    'get-otp:Show the current 2FA/OTP code for an account'
    'seed:Seed an entity locally or on a sandbox'
    'get:Read a value locally or from a sandbox'
    'reset-dbs:Reset databases from the latest backup'
    'reset-dbs-docker:Reset databases (docker)'
    'start-services:Start postgres/redis/elasticsearch'
    'reindex-search:Reindex Elasticsearch (Searchkick)'
    'help:Show usage'
  )
  _describe 'nut command' subcommands
}
compdef _nut nut 2>/dev/null

# Only generic command names are directory-gated, since those genuinely collide
# with other projects. Nutrium-specific commands live under `nut` and are always
# available.
manage_nutrium_aliases() {
  if [[ "$PWD" == "$NUTRIUM_DIR" ]]; then
    web_project_aliases
  else
    clear_web_project_aliases
  fi
}

web_project_aliases() {
  alias rspec="bundle exec rspec"
  alias feature="bundle exec rspec"
  alias rspec_docker="docker exec -ti nutrium-web bundle exec rspec"
  alias feature_docker="docker exec -ti nutrium-web xvfb-run -a bundle exec rspec"
}

clear_web_project_aliases() {
  unalias rspec 2>/dev/null
  unalias feature 2>/dev/null
  unalias rspec_docker 2>/dev/null
  unalias feature_docker 2>/dev/null
}

autoload -U add-zsh-hook
add-zsh-hook chpwd manage_nutrium_aliases
manage_nutrium_aliases
