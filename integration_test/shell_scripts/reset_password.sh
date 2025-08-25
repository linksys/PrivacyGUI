# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"
source "$root/config_loader.sh"

echo "Start to reset password"
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

new_admin_password=$(get_config_value '.newPassword')
# if new_admin_password is empty, exit
if [ -z "$new_admin_password" ]; then
  echo "Error: newAdminPassword is empty. This reset password can only using for set new admin password case"
  exit 1
fi

# set password to default admin password
set_admin_password_to_wifi_password "$new_admin_password"

echo "Reset password Completed"

