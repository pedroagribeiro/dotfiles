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

# Postgres runs as a Docker container even though Rails runs on the host, so
# wait for it to accept connections before running any rake db task against it.
wait_for_postgres() {
  local retries=30

  until PGPASSWORD="nutrium" psql -U nutrium -h localhost -p 5432 -d postgres -c '\q' >/dev/null 2>&1; do
    (( retries-- > 0 )) || { echo "Postgres did not become ready"; return 1; }
    sleep 1
  done
}

wait_for_elasticsearch() {
  local retries=60

  until curl -fs http://localhost:9200/_cluster/health >/dev/null 2>&1; do
    (( retries-- > 0 )) || { echo "Elasticsearch did not become ready"; return 1; }
    sleep 1
  done
}

# Rails runs on the host but every backing service is a Docker container. Bring
# up the full set the app needs: Postgres for data, Redis for the Sidekiq-backed
# jobs (e.g. the Amplitude sign-in event fired on login), Elasticsearch for
# Searchkick. Missing Redis is what makes login blow up with a connection error.
start_nutrium_services() {
  execute "Start backing services (postgres, redis, elasticsearch)" \
    "docker-compose up -d postgres redis elasticsearch" \
    "wait_for_postgres"
}

reindex_nutrium_search() {
  execute "Reindex Elasticsearch (Searchkick)" \
    "wait_for_elasticsearch" \
    "bin/rake searchkick:reindex:all"
}

reset_environment() {
  start_nutrium_services || return 1

  execute "Recreate databases" \
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

# A full reindex rebuilds the Elasticsearch index for every Searchkick model and
# takes ~6.5 minutes. It's rarely what you want: to (re)index a single entity
# it's far faster to run `<Model>.reindex` in the Rails console. Make the user
# opt in explicitly (default No) before spending that time on a full reindex.
confirm_full_reindex() {
  echo ""
  echo "⚠️  Full Elasticsearch reindex requested (--reindex)."
  echo "   This reindexes ALL Searchkick entities and takes ~6.5 minutes."
  echo "   If you only need one entity searchable, it is much faster to run"
  echo "   '<Model>.reindex' in the Rails console instead."
  echo ""

  local response
  read "response?Reindex ALL entities now? [y/N] "

  [[ "$response" == [yY] || "$response" == [yY][eE][sS] ]]
}

reset_nutrium_databases() {
  local backup_file reindex=0

  [[ "$1" == "--reindex" || "$1" == "-r" ]] && reindex=1

  # Confirm up front, before the reset even starts, so a full reindex is never
  # kicked off by mistake. Declining just skips the reindex; the reset proceeds.
  if (( reindex )); then
    confirm_full_reindex || reindex=0
  fi

  # Drives the "[n/total]" progress counter in execute. Four steps normally,
  # five when we also reindex Elasticsearch.
  local EXECUTE_STEP_CURRENT=0 EXECUTE_STEP_TOTAL=4
  (( reindex )) && EXECUTE_STEP_TOTAL=5

  backup_file=$(choose_backup_file) || return 1

  echo "Using backup: $backup_file"

  reset_environment || return 1
  import_data "$backup_file" || return 1
  run_migrations || return 1

  if (( reindex )); then
    reindex_nutrium_search || return 1
  fi
}

reset_nutrium_databases_docker() {
  local backup_file

  # Drives the "[n/total]" progress counter in execute (six steps total).
  local EXECUTE_STEP_CURRENT=0 EXECUTE_STEP_TOTAL=6

  backup_file=$(choose_backup_file) || return 1

  echo "Using backup: $backup_file"

  reset_databases || return 1
  reset_environment_docker || return 1
  import_data "$backup_file" || return 1
  run_migrations_docker || return 1
}
