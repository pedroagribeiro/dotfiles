# Render a whole-second count as a compact "42s" / "1m18s" string.
_format_elapsed() {
  local s=$1
  if (( s >= 60 )); then
    printf '%dm%02ds' $(( s / 60 )) $(( s % 60 ))
  else
    printf '%ds' "$s"
  fi
}

execute() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: execute [-q|--quiet] \"description\" command1 [command2 ...]"
    return 1
  fi

  # Don't announce/notify background jobs; the spinner is our progress signal.
  setopt local_options no_monitor

  local quiet=0
  local show_output=0

  while [[ "$1" == -* ]]; do
    case "$1" in
      -q|--quiet)       quiet=1; shift ;;
      -o|--show-output) show_output=1; shift ;;
      *) break ;;
    esac
  done

  local description="$1"
  shift
  local tmp_output tmp_errors tmp_failed
  tmp_output=$(mktemp)
  tmp_errors=$(mktemp)
  tmp_failed=$(mktemp)

  # Optional "[n/total]" step counter, driven by the caller through
  # dynamically-scoped locals (EXECUTE_STEP_TOTAL / EXECUTE_STEP_CURRENT). When
  # unset, execute behaves exactly as before minus the counter.
  local prefix=""
  if [[ -n "$EXECUTE_STEP_TOTAL" ]]; then
    (( EXECUTE_STEP_CURRENT++ ))
    prefix="[$EXECUTE_STEP_CURRENT/$EXECUTE_STEP_TOTAL] "
  fi

  local -r spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local start=$SECONDS

  # Only animate/colorize when writing to a terminal; keep logs/pipes clean.
  local cr='' clr=''
  local c_reset='' c_dim='' c_arrow='' c_desc='' c_spin='' c_ok='' c_fail=''
  if [[ -t 1 ]]; then
    cr=$'\r'
    clr=$'\e[K'
    c_reset=$'\e[0m'
    c_dim=$'\e[2m'      # step counter + elapsed time
    c_arrow=$'\e[36m'   # the "->" marker (cyan)
    c_desc=$'\e[1m'     # description (bold)
    c_spin=$'\e[33m'    # spinner (yellow)
    c_ok=$'\e[32m'      # ok (green)
    c_fail=$'\e[31m'    # failed (red)
  fi

  # The styled "[n/total] -> description..." prefix, reused on every repaint.
  local head="${c_dim}${prefix}${c_reset}${c_arrow}->${c_reset} ${c_desc}${description}${c_reset}..."

  # Run the commands in the background so the foreground can show progress.
  (
    for cmd in "$@"; do
      : >"$tmp_output"
      : >"$tmp_errors"

      if ! eval "$cmd" >"$tmp_output" 2>"$tmp_errors"; then
        print -r -- "$cmd" >"$tmp_failed"
        exit 1
      fi
    done
  ) &
  local worker=$!

  if [[ -n "$cr" ]]; then
    local i=1
    while kill -0 "$worker" 2>/dev/null; do
      printf '%s%s %s%s%s %s%s%s%s' \
        "$cr" "$head" \
        "$c_spin" "${spin[$i]}" "$c_reset" \
        "$c_dim" "$(_format_elapsed $(( SECONDS - start )))" "$c_reset" "$clr"
      i=$(( i % ${#spin} + 1 ))
      sleep 0.1
    done
  else
    printf '%s ' "$head"
  fi

  wait "$worker"
  local rc=$?
  local elapsed
  elapsed=$(_format_elapsed $(( SECONDS - start )))

  if [[ $rc -ne 0 ]]; then
    local failed_cmd
    failed_cmd=$(<"$tmp_failed")
    printf '%s%s%sfailed%s %s(%s)%s%s\n' \
      "$cr" "${cr:+$head }" "$c_fail" "$c_reset" "$c_dim" "$elapsed" "$c_reset" "$clr"
    echo "Command: $failed_cmd"

    if [[ -s "$tmp_errors" ]]; then
      echo "Error output:"
      cat "$tmp_errors"
    fi

    if [[ -s "$tmp_output" ]]; then
      echo "Command output:"
      cat "$tmp_output"
    fi

    if [[ ! -s "$tmp_errors" && ! -s "$tmp_output" ]]; then
      echo "No output was captured from the failed command."
    fi

    rm -f "$tmp_output" "$tmp_errors" "$tmp_failed"
    return 1
  fi

  printf '%s%s%sok%s %s(%s)%s%s\n' \
    "$cr" "${cr:+$head }" "$c_ok" "$c_reset" "$c_dim" "$elapsed" "$c_reset" "$clr"

  if [[ $show_output -eq 1 && -s "$tmp_output" ]]; then
    cat "$tmp_output"
  fi

  rm -f "$tmp_output" "$tmp_errors" "$tmp_failed"
}
