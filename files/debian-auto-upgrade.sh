#!/bin/bash

set -euf -o pipefail

# shellcheck disable=SC2317
error_handler() {
  local errno="$?"
  echo "Error: ${BASH_SOURCE[1]}:${BASH_LINENO[0]}" \
    "(${BASH_COMMAND} exited with status $errno)" >&2
  exit "${errno}"
}

run() {
  echo "[RUN]" "$@"
  "$@" 2>&1 || return "$?"
  echo
}

wait_for_successful_apt_update() {
  # 720 minutes = 12 hours
  local i
  for ((i = 0; i < 720; i++)); do
    if run apt-get update; then
      break
    else
      echo "No Internet connection. Wait 1 minute..."
      sleep 60
    fi
  done
}

main() {
  trap "error_handler" ERR
  set -o errtrace

  export DEBIAN_FRONTEND=noninteractive

  # shellcheck disable=SC1091
  source /etc/auto-upgrade.conf

  wait_for_successful_apt_update
  run apt-get upgrade -y

  if [[ $DEBIAN_APT_DIST_UPGRADE -ne 0 ]]; then
    run apt-get dist-upgrade -y
  fi

  if [[ $DEBIAN_APT_AUTOREMOVE -ne 0 ]]; then
    run apt-get autoremove --purge -y
  fi

  if [[ $CLEAN_PACKAGES -ne 0 ]]; then
    run apt-get clean -y
  fi
}

main "$@"
