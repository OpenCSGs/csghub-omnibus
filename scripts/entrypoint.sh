#!/bin/bash

# Reconfigure all service enabled default
/usr/bin/csghub-ctl reconfigure

# Start runit daemon
/opt/csghub/embedded/bin/runsvdir-start