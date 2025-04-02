# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"
source "$root/config_loader.sh"

echo "Start skipping PnP flow"
# record time spend
start_time=$(date +%s)
trap 'end_time=$(date +%s); elapsed_time=$((end_time - start_time)); echo "Time spent: $elapsed_time seconds"' EXIT

# make sure it is the target
serial_number=$(get_config_value '.serialNumber')
echo "Target: $serial_number"
wait_for_device_info 10 "$serial_number"
status=$?
if [ $status -ne 0 ]; then
  echo "Error: Current connection node isn't the target."
  exit $status
fi


# check PnP is finished or not
pnp=$(pnp)
is_admin_password_set_by_user=$(is_admin_password_set_by_user)
is_default_admin_password=$(is_default_admin_password)
echo "pnp: $pnp"
echo "is_admin_password_set_by_user: $is_admin_password_set_by_user"
echo "is_default_admin_password: $is_default_admin_password"

# if pnp is false or (is_admin_password_set_by_user is true or is_default_admin_password is false) then exit
if [[ "$pnp" == "false" && ("$is_admin_password_set_by_user" == "true" || "$is_default_admin_password" == "false") ]]; then
  echo "PnP is finished or admin password is set, skip it."
  exit 0
fi


#get serialNumber from get device info result
serial_number=$(get_serial_number)
echo "Record current serial number: $serial_number"

#get current connected wifi and extract ssid
current_wifi=$(get_current_wifi_ssid)
echo "Record current connected WiFi ssid $current_wifi"

# get default WiFi SSID and Password
default_wifi_ssid=$(get_config_value '.defaultWiFi.ssid')
default_wifi_password=$(get_config_value '.defaultWiFi.password')

# get password
password=$(is_default_admin_password_or_get_password)
echo $password
if [[ "$password" == "admin" ]]; then
  echo "Set admin password to default WiFi Password"
  set_admin_password_to_wifi_password "$password"
  password=$default_wifi_password
  echo "Update password: $password"
else
  echo "Set user auto acknowledgement"
  set_user_auto_acknowledgement "$password"
fi
wait_for_seconds 3
set_device_mode_to_master "$password"
wait_for_seconds 30
wait_for_wifi_ssid $default_wifi_ssid 100
connect_to_wifi_ssid_and_check "$default_wifi_ssid" "$default_wifi_password" 60
wait_for_device_info 10 "$serial_number"
echo "Skipping PnP Completed"

