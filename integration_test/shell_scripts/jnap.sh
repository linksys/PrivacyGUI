#!/uer/bin/bash

# imports
root="$(dirname "$0")"
source "$root/config_loader.sh"


 #base64 encode
  base64Encode(){
    local password=$1
    echo -n "admin:${password}" | base64
  }
  base64Decode(){
    local str=$1
    echo -n $str | base64 -d
  }

  # Function to perform JNAP action
  jnap() {
  local action=$1
  local password=$2
  local data=$3

  # Check if action and password are provided
  if [ -z "$action" ]; then
    echo "Usage: jnap <action> [password] [data]"
    return 1
  fi

  # Base64 encode the password
  local encoded_password=$(base64Encode "$password")

  # echo "Performing JNAP Action: $action"
  # echo "Base64 encoded password: $encoded_password"

  # Set default data if not provided
  if [ -z "$data" ]; then
    data='{}'
  fi

  # Perform the curl request
  curl -s 'https://localhost/JNAP/' \
    -H 'Accept: text/plain, */*; q=0.01' \
    -H 'Content-Type: application/json;charset=UTF-8' \
    -H "X-JNAP-Action: $action" \
    -H "X-JNAP-Authorization: Basic $encoded_password" \
    --data-raw "$data" \
    -w '\n'

  # Check the return code of curl
  local curl_status=$?
  if [ $curl_status -ne 0 ]; then
    echo "Error: curl command failed with status code $curl_status"
    return $curl_status
  fi
}

# Perform get device info
get_device_info() {
  local result=$(jnap "http://linksys.com/jnap/core/GetDeviceInfo")
  echo "$result"
}

# Perform factory reset
factory_reset() {
  password=$1
  local result=$(jnap "http://linksys.com/jnap/core/FactoryReset" "$password")
  echo "$result"
}


# Get serial number from device info
get_serial_number() {
  local serialNumber=$(get_device_info | jq -r '.output.serialNumber')
  echo $serialNumber
}

# Get is default admin password
is_default_admin_password() {
  local result=$(jnap "http://linksys.com/jnap/core/IsAdminPasswordDefault" | jq -r '.output.isAdminPasswordDefault')
  echo $result
}

# Get admin password is set by user
is_admin_password_set_by_user() {
  local result=$(jnap "http://linksys.com/jnap/nodes/setup/IsAdminPasswordSetByUser" | jq -r '.output.isAdminPasswordSetByUser')
  echo $result
}

# Get auto configuration supported and user acknowledged auto configuration
pnp() {
  local result=$(jnap "http://linksys.com/jnap/nodes/setup/GetAutoConfigurationSettings")
  local isAutoConfigurationSupported=$(echo $result | jq -r '.output.isAutoConfigurationSupported')
  local isUserAcknowledgedAutoConfiguration=$(echo $result | jq -r '.output.userAcknowledgedAutoConfiguration')
  if [[ "$isAutoConfigurationSupported" == "true" && "$isUserAcknowledgedAutoConfiguration" == "false" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# set device mode to Master
set_device_mode_to_master() {
  password=$1
  local result=$(jnap "http://linksys.com/jnap/nodes/smartmode/SetDeviceMode" "$password" '{"mode":"Master"}')
  echo "$result"
}

# Get device mode
get_device_mode() {
  password=$1
  local result=$(jnap "http://linksys.com/jnap/nodes/smartmode/GetDeviceMode" "$password")
  local deviceMode=$(echo $result | jq -r '.output.mode')
  echo "$deviceMode"
}

# set admin password to default WiFi password
set_admin_password_to_wifi_password() {
  password=$1
  wifi_password=$(get_config_value '.defaultWiFi.password')
  local result=$(jnap "http://linksys.com/jnap/core/SetAdminPassword3" "$password" "{\"adminPassword\":\"$wifi_password\"}")
  echo "$result"
}

# set user auto acknowledgement
set_user_auto_acknowledgement() {
  password=$1
  local result=$(jnap "http://linksys.com/jnap/nodes/setup/SetUserAcknowledgedAutoConfiguration" "$password" '{}')
  echo "$result"
}

# Perform bt auto onboarding
bt_auto_onboarding() {
  password=$1
  local result=$(janp "http://linksys.com/jnap/nodes/autoonboarding/StartBluetoothAutoOnboarding2" "$password" '{}')
  echo "$result"
}

# This can only work on un-configured mode
pre_paired() {
  echo $(curl -G -d "CMD=trigger&mac=" 'https://localhost/cgi-bin/onboarding.cgi' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'Accept-Language: en-US,en;q=0.9,zh-TW;q=0.8,zh;q=0.7' \
  -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
  -H 'Connection: keep-alive' \
  -w '\n' \
  --insecure -v --location-trusted)
}






