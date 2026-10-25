#!/bin/bash
#
# Copyright (C) 2025-2026 James Cherti
# URL: https://github.com/jamescherti/ansible-role-auto-upgrade
#
# Distributed under terms of the MIT license.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

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
