# imports
root="$(dirname "$0")"
source "$root/utils.sh"
source "$root/jnap.sh"

# load nginx path from test_nginx
nginx_path=$(cat "$root"/../test_nginx)
echo "Nginx path: $nginx_path"

conf_file_path="$nginx_path/servers/router.conf"
# replace server regex {ip} to gateway ip, NOTE: This wifi case!
gateway_ip=$(networksetup -getinfo Wi-Fi | grep 'Router' | awk '/^Router:/{print $2}')
# Use regex to match any IP address format
sed -i '' "s/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/$gateway_ip/g" "$conf_file_path"

echo "Replace server ip to $gateway_ip"



# check if nginx is running
if pgrep -x "nginx" > /dev/null
then
    echo "nginx is running, stop it first"
    nginx -s stop
    wait_for_seconds 5
fi

# start nginx
echo "Starting nginx..."
nginx
wait_for_seconds 5
echo "nginx started."
