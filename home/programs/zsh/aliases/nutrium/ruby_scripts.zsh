execute_ruby_script() {
  local web_container_name="nutrium-web"
  local script_name="$1"
  shift

  execute "Running: $script_name" \
    "docker cp $DOTFILES/home/programs/zsh/aliases/nutrium/ruby/$script_name $web_container_name:/tmp/$script_name" \
    "docker exec $web_container_name rails runner /tmp/$script_name $(printf '%q ' "$@")"
}

create_patient() {
  local default_email="pedroribeiro@nutrium.com"
  local default_company="nutrium"

  [[ "$1" == "--help" ]] && {
    echo "Usage: create_patient <email> <company>"
    echo "Defaults - email: \"$default_email\" | company: \"$default_company\""
    return
  }

  local email=${1:-$default_email}
  local company=${2:-$default_company}

  execute_ruby_script "create_patient.rb" "$email" "$company"
}

create_questionaires() {
  [[ "$1" == "--help" ]] && {
    echo "Usage: create_questionaires"
    return
  }

  execute_ruby_script "create_questionaires.rb"
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

  execute_ruby_script "create_food_diaries_for_patient.rb" "$email" "$food_diaries" "$filled"
}
