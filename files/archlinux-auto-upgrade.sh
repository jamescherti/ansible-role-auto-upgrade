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

is_pacman_running() {
  pgrep -x pacman >/dev/null || return 1
}

delete_pacman_db_lck() {
  if is_pacman_running; then
    echo "Error: pacman is already running." >&2
    exit 1
  fi

  if [ -f /var/lib/pacman/db.lck ]; then
    rm -f /var/lib/pacman/db.lck
  fi
}

download_package_db() {
  echo "[INFO] Download the package database..."
  pacman --noconfirm -Sy
}

upgrade_keyring_and_pacman() {
  download_package_db
  upgrade_specific_packages archlinux-keyring
}

wait_for_successful_pacman_update() {
  # 720 minutes = 12 hours
  local i
  for ((i = 0; i < 720; i++)); do
    if download_package_db; then
      break
    else
      echo "No Internet connection. Wait 1 minute..."
      sleep 60
    fi
  done
}

upgrade_all_packages() {
  run pacman --noconfirm -Su
}

clean_package_cache() {
  run pacman --noconfirm -Scc
}

main() {
  trap "error_handler" ERR
  set -o errtrace

  # shellcheck disable=SC1091
  source /etc/auto-upgrade.conf

  delete_pacman_db_lck
  wait_for_successful_pacman_update
  upgrade_all_packages
  if [[ $CLEAN_PACKAGES -ne 0 ]]; then
    clean_package_cache
  fi
}

main "$@"
