execute_ruby_script() {
  local web_container_name="nutrium-web"
  local script_name="$1"
  shift

  execute "Running: $script_name" \
    "docker cp $DOTFILES/home/programs/zsh/aliases/nutrium/ruby/$script_name $web_container_name:/tmp/$script_name" \
    "docker exec $web_container_name rails runner /tmp/$script_name $(printf '%q ' "$@")"
}

execute_ruby_script_host() {
  local script_name="$1"
  shift

  # `execute` redirects the script's stdout to a temp file, so the script can't
  # detect the terminal itself. Detect it here (before that redirection) and
  # pass the result through so the summary knows whether to emit ANSI color.
  local color=0
  [[ -t 1 ]] && color=1

  execute -o "Running (host): $script_name" \
    "(cd $NUTRIUM_DIR && SEED_SUMMARY_COLOR=$color bin/rails runner \"$DOTFILES/home/programs/zsh/aliases/nutrium/ruby/$script_name\" $(printf '%q ' "$@"))"
}

create_patient() {
  local default_email="pedroribeiro@nutrium.com"
  local default_company="nutrium"

  [[ "$1" == "--help" ]] && {
    echo "Usage: create_patient <email> <company> [professional_name]"
    echo "Defaults - email: \"$default_email\" | company: \"$default_company\""
    echo "           professional_name: the professional shipped in the backup"
    return
  }

  local email=${1:-$default_email}
  local company=${2:-$default_company}
  local professional=${3:-}

  execute_ruby_script_host "create_patient.rb" "$email" "$company" "$professional"
}

create_questionaires() {
  [[ "$1" == "--help" ]] && {
    echo "Usage: create_questionaires"
    return
  }

  execute_ruby_script_host "create_questionaires.rb"
}

get_otp() {
  local default_email="pedroribeiro@nutrium.com"

  [[ "$1" == "--help" ]] && {
    echo "Usage: get_otp <email>"
    echo "Prints the current (time-based) 2FA / OTP code for the account."
    echo "Default - email: \"$default_email\""
    return
  }

  local email=${1:-$default_email}

  execute_ruby_script_host "get_otp.rb" "$email"
}

create_food_diaries_for_patient() {
  local default_email="pedroribeiro@nutrium.com"
  local default_food_diaries=5
  local default_filled="true"

  [[ "$1" == "--help" ]] && {
    echo "Usage: create_food_diaries_for_patient <email> <food_diaries> <filled>"
    echo "Defaults - email: \"$default_email\" | food_diaries: $default_food_diaries | filled: \"$default_filled\""
    return
  }

  local email=${1:-$default_email}
  local food_diaries=${2:-$default_food_diaries}
  local filled=${3:-$default_filled}

  execute_ruby_script_host "create_food_diaries_for_patient.rb" "$email" "$food_diaries" "$filled"
}

create_us_professional() {
  local default_email="us-pro@nutrium.com"
  local default_name="John Smith"

  [[ "$1" == "--help" ]] && {
    echo "Usage: create_us_professional <email> <name>"
    echo "Defaults - email: \"$default_email\" | name: \"$default_name\""
    return
  }

  local email=${1:-$default_email}
  local name=${2:-$default_name}

  execute_ruby_script_host "create_professional.rb" "US" "$email" "$name"
}

create_pt_professional() {
  local default_email="pt-pro@nutrium.com"
  local default_name="Ana Silva"

  [[ "$1" == "--help" ]] && {
    echo "Usage: create_pt_professional <email> <name>"
    echo "Defaults - email: \"$default_email\" | name: \"$default_name\""
    return
  }

  local email=${1:-$default_email}
  local name=${2:-$default_name}

  execute_ruby_script_host "create_professional.rb" "PT" "$email" "$name"
}
