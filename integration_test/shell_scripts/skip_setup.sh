# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"
source "$root/config_loader.sh"

echo "Start skipping Setup flow"
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

# check setup is finished or not
autoConfigurationSettings=$(get_auto_configration_settings)
isAutoConfigurationSupported=$(echo $autoConfigurationSettings | jq -r '.output.isAutoConfigurationSupported')
autoConfigurationMethod=$(echo $autoConfigurationSettings | jq -r '.output.autoConfigurationMethod')
isUserAcknowledgedAutoConfiguration=$(echo $autoConfigurationSettings | jq -r '.output.userAcknowledgedAutoConfiguration')
is_admin_password_set_by_user=$(is_admin_password_set_by_user)
is_default_admin_password=$(is_default_admin_password)
echo "isAutoConfigurationSupported: $isAutoConfigurationSupported"
echo "autoConfigurationMethod: $autoConfigurationMethod"
echo "isUserAcknowledgedAutoConfiguration: $isUserAcknowledgedAutoConfiguration"
echo "is_admin_password_set_by_user: $is_admin_password_set_by_user"
echo "is_default_admin_password: $is_default_admin_password"

need_setup="false"
if [[ "$isAutoConfigurationSupported" == "true" && "$isUserAcknowledgedAutoConfiguration" == "false" ]]; then
    need_setup="true"
else
    need_setup="false"
fi

if [[ "$need_setup" == "false" && ("$is_admin_password_set_by_user" == "true" || "$is_default_admin_password" == "false") ]]; then
  echo "Setup is finished or admin password is set, skip it."
  exit 0
fi

#else do setup

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

if [[ "$autoConfigurationMethod" == "AutoParent" ]]; then
    #AutoParent
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
    else
        echo "Set user auto acknowledgement"
        set_user_auto_acknowledgement "$password"
        wait_for_seconds 3
    fi

else
    #Pnp
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
fi

wait_for_wifi_ssid $default_wifi_ssid 100
connect_to_wifi_ssid_and_check "$default_wifi_ssid" "$default_wifi_password" 60
wait_for_device_info 10 "$serial_number"
echo "Skipping setup Completed"