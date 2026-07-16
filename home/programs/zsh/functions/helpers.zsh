execute() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: execute [-q|--quiet] \"description\" command1 [command2 ...]"
    return 1
  fi

  local quiet=0

  if [[ "$1" == "-q" || "$1" == "--quiet" ]]; then
    quiet=1
    shift
  fi

  local description="$1"
  shift
  local tmp_errors
  tmp_errors=$(mktemp)

  echo -n "-> $description... "

  local failed=0
  local failed_cmd=""

  for cmd in "$@"; do
    if ! eval "$cmd" >/dev/null 2>"$tmp_errors"; then
      failed=1
      failed_cmd="$cmd"
      break
    fi
  done

  if [[ $failed -eq 1 ]]; then
    echo "failed"
    if [[ $quiet -eq 0 ]]; then
      echo "$failed_cmd"
      cat "$tmp_errors"
    fi
    rm -f "$tmp_errors"
    return 1
  fi

  echo "ok"
  rm -f "$tmp_errors"
}
