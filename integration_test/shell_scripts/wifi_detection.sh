#!/usr/bin/sh

# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"
source "$root/config_loader.sh"

# get default WiFi SSID and Password
default_wifi_ssid=$(get_config_value '.defaultWiFi.ssid')
default_wifi_password=$(get_config_value '.defaultWiFi.password')

echo "Start WiFi detection, Target WiFi SSID $default_wifi_ssid"

while true; do

    current=$(get_current_wifi_ssid)

    if [[ $current != $default_wifi_ssid ]]; then
      connect_to_wifi_ssid_and_check "$default_wifi_ssid" "$default_wifi_password" 10
    fi

    sleep 5
done