#!/bin/bash

# Start runit daemon
/opt/csghub/embedded/bin/runsvdir-start &

# waiting for runit start
sleep 2

# Reconfigure all service enabled default
/usr/bin/csghub-ctl reconfigure

# hangup
wait