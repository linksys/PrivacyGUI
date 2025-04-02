# imports
root="$(dirname "$0")"
source "$root/integration_test/shell_scripts/config_loader.sh"

force="local"
cloud="qa"
picker=false

start_time=$(date +%s)
GREEN='\033[0;32m'
NC='\033[0m'
LINE_BREAK="${GREEN} ------------ ${NC}"

while getopts t:d:p: flag
do
    case "${flag}" in
        t) testcase=${OPTARG};;
        d) data=${OPTARG};;
        p) p=${OPTARG};;
    esac
done
if [ -z "$testcase" ]; then
    echo "ERROR: Empty testcase file."
    exit 1
fi
if [ -z "$data" ]; then
    echo "Empty data file."
fi

count=0
successed=0
failed=0
cases=($(jq -r '.files[]' $testcase))
flutter pub get

for case in "${cases[@]}"; do
    #init config file
    init_config $data
    metaPath="./integration_test/test_meta/$case.json"
    metaJson=$(cat $metaPath)

    # get additional config from meta and merge to main config
    caseAdditionalConfig=$(jq -n -r --arg m "$metaJson" '$m' | jq -r '.config')
    set_config "$caseAdditionalConfig"

    caseName=$(jq -n -r --arg m "$metaJson" '$m' | jq -r '.name')
    caseDescription=$(jq -n -r --arg m "$metaJson" '$m' | jq -r '.description')
    casePath=$(jq -n -r --arg m "$metaJson" '$m' | jq -r '.target')

    caseSetup=($(jq -n -r --arg m "$metaJson" '$m' | jq -r '.setUp // [] | .[]'))
    caseTearDown=($(jq -n -r --arg m "$metaJson" '$m' | jq -r '.tearDown // [] | .[]'))
    shActionPath="./integration_test/shell_scripts/"

    count=$(( $count + 1 ))
    echo "$LINE_BREAK"
    echo "${GREEN} TEST ${count} ${NC}"
    echo "Case Name: $caseName"
    echo "Case Description: $caseDescription"
    echo "Case Path: $casePath"
    echo "$LINE_BREAK"  

    # setActions
    echo "Case Setup: $caseSetup"
    for action in "${caseSetup[@]}"; do
        actionPath="$shActionPath$action.sh"
        echo "Case Setup Action: $action"
        bash "$actionPath"
    done
    
    # Run the WiFi detection script on the background
    sh ./integration_test/shell_scripts/wifi_detection.sh &
    pid=$!
    
    echo "Initiate Flutter Integration Test..."
    result=$(flutter drive --driver=test_driver/integration_test.dart \
    --target=$casePath \
    --dart-define=force="${force}" \
    --dart-define=cloud_env="${cloud}" \
    --dart-define=enable_env_picker="${picker}" \
    --dart-define-from-file=$config_temp_path \
    --no-pub \
    --browser-name chrome \
    --web-port 61672 \
    --web-launch-url "https://localhost/" \
    --no-headless \
    --keep-app-running \
    -d web-server)
    if [[ "$result" == *"All tests passed."* ]]; then
        # Passed
        successed=$(( $successed + 1 ))
        echo "...passed."
    else
        # Failed
        failed=$(( $failed + 1 ))
        echo "...failed."
        echo "-------------------"
        echo "Result: $result"
        echo "-------------------"
        # Extract the failure details
        message=$(dart run ./test_scripts/extract_failure_messages.dart "$result")
        echo "$message"
    fi
    Kill the WiFi detection process
    kill -9 $pid
    echo "Case TearDown: $caseTearDown"
    for action in "${caseTearDown[@]}"; do
        actionPath="$shActionPath$action.sh"
        echo "Case TearDown Action Path: $actionPath"
        bash "$actionPath" true
    done
done
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "*******************************"
echo "Time spent: $elapsed_time seconds"
echo "Passed: $successed"
echo "Failed: $failed"
echo "Total: $count"
echo "*******************************"
# exit (1) if any failed
if [ "$failed" -gt 0 ]; then
    exit 1
fi
exit 0
#
