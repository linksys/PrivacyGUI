# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"

echo "Start Pre-paired process"
# record time spend
start_time=$(date +%s)
trap 'end_time=$(date +%s); elapsed_time=$((end_time - start_time)); echo "Time spent: $elapsed_time seconds"' EXIT

# make sure it is the target
serial_number=$(jq -r '.serialNumber' "$root"/../test_config.json)
echo "Target: $serial_number"
wait_for_device_info 10 "$serial_number"
status=$?
if [ $status -ne 0 ]; then
  echo "Error: Current connection node isn't the target."
  exit $status
fi

#get serialNumber from get device info result
serial_number=$(get_serial_number)
echo "Record current serial number: $serial_number"

#get current connected wifi and extract ssid
current_wifi=$(get_current_wifi_ssid)
echo "Record current connected WiFi ssid $current_wifi"

# get default WiFi SSID and Password
default_wifi_ssid=$(jq -r '.defaultWiFi.ssid' "$root"/../test_config.json)
default_wifi_password=$(jq -r '.defaultWiFi.password' "$root"/../test_config.json)

# get password
password=$(is_default_admin_password_or_get_password)
if [[ "$password" != "admin" ]]; then
  echo "Pre-paired process can only initiate on un-configured status"
  exit 1
fi

pre_paired
wait_for_seconds 120
wait_for_wifi_ssid $default_wifi_ssid 100
connect_to_wifi_ssid_and_check "$default_wifi_ssid" "$default_wifi_password" 60
wait_for_device_info 10 "$serial_number"
echo "Pre-paired completed"

