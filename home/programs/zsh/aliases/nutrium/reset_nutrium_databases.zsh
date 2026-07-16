choose_backup_file() {
  local backup_dir="$HOME/Code/healthium/backups"
  local backup_file

  backup_file=($backup_dir/*.sql(om[1]))

  if [[ ! -f $backup_file ]]; then
    echo "Could not find database backup file in directory: $backup_dir"
    return 1
  fi

  echo "$backup_file"
}

reset_databases() {
  execute -q "Reset test database" \
    "make clean reset_db_test"

  execute -q "Reset development database" \
    "make clean reset_db"
}

reset_environment() {
  execute "Start environment" \
    "make start"

  execute "Restore databases" \
    "bin/rake db:environment:set RAILS_ENV=development" \
    "bin/rake db:drop" \
    "bin/rake db:create"
}

reset_environment_docker() {
  execute "Start environment" \
    "make start"

  execute "Restore databases" \
    "docker exec nutrium-web rake db:environment:set RAILS_ENV=development" \
    "docker exec nutrium-web rake db:drop" \
    "docker exec nutrium-web rake db:create"
}

import_data() {
  local backup_file="$1"

  execute "Import data from backup" \
    "PGPASSWORD=\"nutrium\" psql -U nutrium -h localhost -p 5432 nutrium_test < $backup_file" \
    "PGPASSWORD=\"nutrium\" psql -U nutrium -h localhost -p 5432 nutrium_development < $backup_file"
}

run_migrations() {
  execute "Migrate databases" \
    "bin/rake db:migrate RAILS_ENV=test" \
    "bin/rake db:migrate"
}

run_migrations_docker() {
  execute "Migrate database" \
    "docker exec nutrium-web rake db:migrate RAILS_ENV=test" \
    "docker exec nutrium-web rake db:migrate"
}

reset_nutrium_databases() {
  local backup_file

  backup_file=$(choose_backup_file) || return 1

  echo "Using backup: $backup_file"

  reset_databases
  reset_environment
  import_data "$backup_file"
  run_migrations
}

reset_nutrium_databases_docker() {
  local backup_file

  backup_file=$(choose_backup_file) || return 1

  echo "Using backup: $backup_file"

  reset_databases
  reset_environment_docker
  import_data "$backup_file"
  run_migrations_docker
}
