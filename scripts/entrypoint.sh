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

# Generate seed file for create api token
[ -s /opt/csghub/etc/csghub/.seed ] || date +%s | md5sum | head -c 32 > /opt/csghub/etc/csghub/.seed

# Reconfigure all service enabled
cd / && retry /usr/bin/csghub-ctl reconfigure

echo -e "\nService will be ready in minute.\n"
echo -e "Initialization information is in the /etc/csghub."
echo -e "Please login using /etc/csghub/init_root_password\n"

# Start runit daemon
/opt/csghub/embedded/bin/runsvdir-start