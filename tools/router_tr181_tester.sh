#!/bin/bash
# Router TR-181 Tester Tool
# This tool securely SSHs into the Linksys router to execute TR-181 commands.
# Usage: ./tools/router_tr181_tester.sh "<command>"

if [ -z "$1" ]; then
    echo "Usage: ./tools/router_tr181_tester.sh \"<command>\""
    echo "Examples:"
    echo "  ./tools/router_tr181_tester.sh \"ubus call bbfdm get '{\\\"path\\\":\\\"Device.DeviceInfo.\\\"}'\""
    echo "  ./tools/router_tr181_tester.sh \"obuspa -s /tmp/usp_cli -c get 'Device.DeviceInfo.'\""
    exit 1
fi

COMMAND="$1"
ROUTER_IP="192.168.1.1"
PASSWORD="7qW19st5m@"

EXP_FILE=$(mktemp)
cat << 'EOF' > "$EXP_FILE"
set timeout 20
set router_ip [lindex $argv 0]
set password [lindex $argv 1]
set command [lindex $argv 2]

spawn ssh -o StrictHostKeyChecking=no root@$router_ip $command
expect {
    "password:" {
        send "$password\r"
        exp_continue
    }
    eof
}
EOF

expect "$EXP_FILE" "$ROUTER_IP" "$PASSWORD" "$COMMAND"
rm -f "$EXP_FILE"
