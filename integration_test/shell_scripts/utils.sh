#!/bin/bash

# imports
root="$(dirname "$0")"
source "$root/jnap.sh"
source "$root/config_loader.sh"

# function to wait for x seconds 
wait_for_seconds() {
  local seconds=$1
  echo "Waiting for $seconds seconds..."
  sleep $seconds
  echo "Finished waiting."
}

# function to wait for a specific string in the output of a command
wait_for_string() {
  local command=$1
  local expected_string=$2
  local timeout=$3
  local start_time=$(date +%s)

  echo "Waiting for '$expected_string' in output of '$command'..."

  while true; do
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))

    if [[ "$elapsed_time" -ge "$timeout" ]]; then
      echo "Timeout reached. '$expected_string' not found in output."
      return 1
    fi

    local output=$($command 2>&1)
    if [[ "$output" == *"$expected_string"* ]]; then
      echo "Found '$expected_string' in output."
      return 0
    fi

    sleep 1
  done
}

# wait for get device info response, if serial number passed, then check serial number matches
wait_for_device_info() {
  local timeout=$1
  local serial_number=$2
  local start_time=$(date +%s)

  echo "Waiting for device info..."

  while true; do
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))

    if [[ "$elapsed_time" -ge "$timeout" ]]; then
      echo "Timeout reached. Device info not received."
      return 1
    fi

    local output=$(get_device_info)
    if [[ "$output" == *"\"result\": \"OK\""* ]]; then
      if [ -z "$serial_number" ]; then
        echo "Device info received."
        return 0
      else
        local current_serial_number=$(echo "$output" | jq -r '.output.serialNumber')
        if [[ "$current_serial_number" == "$serial_number" ]]; then
          echo "Device info received and serial number matched."
          return 0
        else
          echo "Device info received but serial number not matched."
        fi
      fi
    fi

    sleep 1
  done
}

# wait for target wifi ssid shown on wifi site survey
wait_for_wifi_ssid() {
  local target_ssid=$1
  local timeout=$2
  local start_time=$(date +%s)
  
  # Skip if wiredTesting is True
  wiredTesting=$(get_global_config_value '.wired')
  echo "wiredTesting: $wiredTesting"
  if [ "$wiredTesting" == "true" ]; then
    echo "Wired testing is enabled. Skipping wifi SSID wait."
    return 0
  fi

  echo "Waiting for wifi SSID '$target_ssid'..."

  while true; do
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))

    if [[ "$elapsed_time" -ge "$timeout" ]]; then
      echo "Timeout reached. Wifi SSID '$target_ssid' not found."
      return 1
    fi

    local output=$(get_wifi_site_survey)
    if [[ "$output" == *"$target_ssid"* ]]; then
      echo "Wifi SSID '$target_ssid' found."
      return 0
    fi

    sleep 5
  done
}

# wifi Site survey
get_wifi_site_survey() {
  local output=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -s | awk '{print $1}')
  echo "$output"
}

# get current WiFi connection SSID
get_current_wifi_ssid() {
  local current_ssid=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F': ' '/ SSID/ {print $2}')
  if [ -z "$current_ssid" ]; then
    current_ssid=$(system_profiler SPAirPortDataType | grep -A 2 "Current Network Information:" | awk 'NR==2 {gsub(/^[[:space:]]+/, ""); sub(/:$/, ""); print}')
  fi
  echo "$current_ssid"
}


# check current WiFi connection is target SSID
check_current_wifi_ssid() {
  local target_ssid=$1
  local timeout=$2
  local start_time=$(date +%s)

  echo "Checking current wifi SSID is '$target_ssid'..."

  while true; do
    local current_time=$(date +%s)
    local elapsed_time=$((current_time - start_time))

    if [[ "$elapsed_time" -ge "$timeout" ]]; then
      echo "Timeout reached. Current wifi SSID is not '$target_ssid'."
      return 1
    fi

    local current_ssid=$(get_current_wifi_ssid)
    if [[ "$current_ssid" == "$target_ssid" ]]; then
      echo "Current wifi SSID is '$target_ssid'."
      return 0
    fi

    sleep 1
  done
}


# connect to target SSID with password and wait for connection
connect_to_wifi_ssid_and_check() {
  local target_ssid=$1
  local password=$2
  local timeout=$3
  local start_time=$(date +%s)

    # Skip if wiredTesting is True
  wiredTesting=$(get_global_config_value '.wired')
  if [ "$wiredTesting" == "true" ]; then
    echo "Wired testing is enabled. Skipping check connected WiFi."
    return 0
  fi

  echo "Connecting to wifi SSID '$target_ssid'..."

  # Connect to the target SSID
  networksetup -setairportnetwork en0 "$target_ssid" "$password"

  check_current_wifi_ssid $target_ssid $timeout
  local status=$?
  if [ $status -ne 0 ]; then
    echo "Timeout! Not able to connect to wifi SSID '$target_ssid"
    return $status
  fi
  echo "Connected to wifi SSID '$target_ssid'."
  
}

# check is default admin password, if not, get password from config
is_default_admin_password_or_get_password() {
  if [ $(is_default_admin_password) == "true" ] && [ $(is_admin_password_set_by_user) == "false" ]; then
    echo "admin"
  else
    password=$(get_config_value '.password')
    echo $password
  fi
}




