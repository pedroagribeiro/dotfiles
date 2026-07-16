for helper in "$DOTFILES"/home/programs/zsh/aliases/nutrium/*.zsh; do
  source "$helper"
done

alias hum='cd ~/Code/healthium'
alias nut='cd ~/Code/healthium/nutrium'

manage_nutrium_aliases() {
  if [[ "$PWD" == "$HOME/Code/healthium/nutrium" ]]; then
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
  alias reset_dbs="reset_nutrium_databases"
  alias reset_dbs_docker="reset_nutrium_databases_docker"
  alias create_patient="create_patient"
  alias create_questionaires="create_questionaires"
  alias create_food_diaries="create_food_diaries_for_patient"
}

clear_web_project_aliases() {
  unalias rspec 2>/dev/null
  unalias feature 2>/dev/null
  unalias rspec_docker 2>/dev/null
  unalias feature_docker 2>/dev/null
  unalias reset_dbs 2>/dev/null
  unalias reset_dbs_docker 2>/dev/null
  unalias create_patient 2>/dev/null
  unalias create_questionaires 2>/dev/null
  unalias create_food_diaries 2>/dev/null
}

autoload -U add-zsh-hook
add-zsh-hook chpwd manage_nutrium_aliases
manage_nutrium_aliases
