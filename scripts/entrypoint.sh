#!/bin/bash

# Start runit daemon
/opt/csghub/embedded/bin/runsvdir-start &

# Waiting for runit to start
sleep 2

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

# Repair function: check and remove invalid services
repair_services() {
  local SERVICE_DIR="/opt/csghub/service"
  local removed_count=0
  echo "Starting service health check..."

  for service in "$SERVICE_DIR"/*; do
    if [ -d "$service" ]; then
      local service_name=$(basename "$service")
      local ok_file="$service/log/supervise/pid"

      if [ ! -f "$ok_file" ]; then
        echo "WARNING: Service $service_name is missing supervise/ok file - removing"
        rm -rf "$service"

        if [ -d "$service" ]; then
          echo "ERROR: Failed to remove service $service_name"
        else
          echo "Successfully removed invalid service $service_name"
          ((removed_count++))
        fi
      fi
    fi
  done

  echo "Service health check completed. Removed $removed_count invalid services."
  return $removed_count
}

# Reconfigure all service enabled
retry /usr/bin/csghub-ctl reconfigure

# Waiting for service ready
sleep 2

# Run service repair
repair_services
removed_count=$?
# Only reconfigure if services were removed
if [ $removed_count -gt 0 ]; then
  echo "$removed_count services were removed, reconfiguring..."
  retry /usr/bin/csghub-ctl reconfigure
else
  echo "All services are healthy."
fi

# Hangup
wait