#!/usr/bin/sh

# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"

# get default WiFi SSID and Password
default_wifi_ssid=$(jq -r '.defaultWiFi.ssid' "$root"/../test_config.json)
default_wifi_password=$(jq -r '.defaultWiFi.password' "$root"/../test_config.json)

echo "Start WiFi detection, Target WiFi SSID $default_wifi_ssid"

while true; do

    current=$(get_current_wifi_ssid)

    if [[ $current != $default_wifi_ssid ]]; then
      connect_to_wifi_ssid_and_check "$default_wifi_ssid" "$default_wifi_password" 10
    fi

    sleep 5
done