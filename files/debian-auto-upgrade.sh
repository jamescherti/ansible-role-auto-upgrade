#!/bin/bash

set -euf -o pipefail

# shellcheck disable=SC2317
error_handler() {
  local errno="$?"
  echo "Error: ${BASH_SOURCE[1]}:${BASH_LINENO[0]}" \
    "(${BASH_COMMAND} exited with status $errno)" >&2
  exit "${errno}"
}

wait_for_successful_apt_update() {
  # 720 minutes = 12 hours
  local i
  for ((i = 0; i < 720; i++)); do
    if apt-get update >/dev/null 2>&1; then
      break
    else
      echo "No Internet connection. Wait 1 minute..."
      sleep 60
    fi
  done
}

run() {
  echo "[RUN]" "$@"
  "$@"
}

main() {
  trap "error_handler" ERR
  set -o errtrace

  export DEBIAN_FRONTEND=noninteractive

  wait_for_successful_apt_update
  run apt-get upgrade -y
  run apt-get autoremove --purge -y
  run apt-get clean -y
}

main "$@"
