# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"
source "$root/config_loader.sh"

echo "Start checking auto parent flow"

password=$(is_default_admin_password_or_get_password)

# Function to wait for device mode to be master
wait_for_device_mode_to_master() {
  local max_attempts=$1
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    local mode=$(get_device_mode $password)
    if [ "$mode" = "Master" ]; then
      echo "Device mode is now Master"
      return 0
    fi
    # echo "Current device mode: $mode"
    # echo "Waiting for device mode to be Master (attempt $attempt/$max_attempts)..."
    sleep 5
    attempt=$((attempt + 1))
  done
  
  echo "Timeout waiting for device mode to be Master"
  return 1
}

wait_for_device_mode_to_master 60  # Wait up to 300 seconds (60 attempts * 5 seconds)
status=$?
if [ $status -ne 0 ]; then
  echo "Error: Failed to set device mode to Master"
  exit $status
fi

echo "Checking auto parent Completed"

