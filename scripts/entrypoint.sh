#!/bin/bash

retry() {
  local n=1 max=3 delay=5
  while ! "$@"; do
    ((n++))
    if ((n > max)); then
      echo "The command has failed after $max attempts."
      return 1
    fi

    echo "Command failed. Attempt $n/$max:"
    sleep $delay
  done
}

# Reconfigure all service enabled
retry /usr/bin/csghub-ctl reconfigure

# Start runit daemon
/opt/csghub/embedded/bin/runsvdir-start