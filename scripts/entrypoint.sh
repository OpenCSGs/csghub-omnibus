#!/bin/bash

# Start runit daemon
/opt/csghub/embedded/bin/runsvdir-start &

# waiting for runit start
sleep 2

retry() {
  local n=1 max=3 delay=5
  while ! "$@"; do
    ((n++))
    if ((n > max)); then
      log "ERRO" "The command has failed after $max attempts."
      return 1
    fi

    log "WARN" "Command failed. Attempt $n/$max:"
    sleep $delay
  done
}

# Reconfigure all service enabled default
retry /usr/bin/csghub-ctl reconfigure

# hangup
wait