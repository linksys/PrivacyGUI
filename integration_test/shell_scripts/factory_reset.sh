# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"
source "$root/config_loader.sh"

# record time spend
start_time=$(date +%s)
trap 'end_time=$(date +%s); elapsed_time=$((end_time - start_time)); echo "Time spent: $elapsed_time seconds"' EXIT


echo "Starting factory reset..."
#get serialNumber from get device info result
serial_number=$(get_serial_number)
echo "Record current serial number: $serial_number"

#get current connected wifi and extract ssid
current_wifi=$(get_current_wifi_ssid)
echo "Record current connected WiFi ssid $current_wifi"

# get password
password=$(is_default_admin_password_or_get_password)

# get default WiFi SSID and Password
default_wifi_ssid=$(get_config_value '.defaultWiFi.ssid')
default_wifi_password=$(get_config_value '.defaultWiFi.password')

echo "$default_wifi_ssid"
echo "$default_wifi_password"

# # reset to factory default
echo "Resetting to factory default..."
factory_reset $password
wait_for_seconds 120
wait_for_wifi_ssid $default_wifi_ssid 100
connect_to_wifi_ssid_and_check "$default_wifi_ssid" "$default_wifi_password" 60
wait_for_device_info 10 "$serial_number"
echo "Factory reset completed."
