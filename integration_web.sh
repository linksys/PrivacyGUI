# imports
root="$(dirname "$0")"
source "$root/integration_test/shell_scripts/config_loader.sh"
source "$root/integration_test/shell_scripts/test_result_logger.sh"


# --- Function: Check for and kill a process by name ---
kill_process() {
    local name_to_kill="wifi_detection.sh"

    # Use ps and grep to find matching process IDs (PIDs)
    # [g]rep is used to avoid matching the grep command itself
    pids=$(ps aux | grep -v 'grep' | grep -w "$name_to_kill" | awk '{print $2}')

    # Check if any PIDs were found
    if [ -z "$pids" ]; then
        echo "No running processes found for: $name_to_kill"
    else
        echo "Found the following processes, preparing to terminate:"
        echo "$pids"

        # Terminate the processes
        # Use xargs to pass the list of PIDs to the kill command
        echo "$pids" | xargs kill -9
        echo "All related processes have been terminated."
    fi
}

force="local"
cloud="qa"
picker=false

start_time=$(date +%s)
GREEN='\033[0;32m'
NC='\033[0m'
LINE_BREAK="${GREEN} ------------ ${NC}"

while getopts t:d:g: flag
do
    case "${flag}" in
        t) testcase=${OPTARG};;
        d) data=${OPTARG};;
        g) tags=${OPTARG};;
    esac
done

if [[ -z "$testcase" && -z "$tags" ]]; then
    echo "ERROR: Empty testcase file or tags."
    exit 1
fi
# if [ -z "$data" ]; then
#     echo "Empty data file."
#     exit 1
# fi

# check tags which include tag string from json files in test_meta folder
if [ ! -z "$tags" ]; then
    testcaseArray=()
    echo "Running with tags: $tags"
    # for loop for tag variable split with , or a single tag
    for tag in $(echo "$tags" | tr ',' ' '); do
        # for loop for .json file in test_meta filder
        for file in ./integration_test/test_meta/*.json; do
            # check if tag is in the json file
            if jq -e ".tags | contains([\"$tag\"])" "$file" > /dev/null 2>&1; then
                # add file name into testcaseArray
                file=$(basename "$file" .json)
                testcaseArray+=("$file")
            fi
        done
    done
    # remove duplicate testcase from testcaseArray
    # IFS=
    declare -a uniqueTestcaseArray
    for item in "${testcaseArray[@]}"; do
        found=false
        for uniqueItem in "${uniqueTestcaseArray[@]}"; do
            if [[ "$item" == "$uniqueItem" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" == false ]]; then
            uniqueTestcaseArray+=("$item")
        fi
    done
    testcaseArray=("${uniqueTestcaseArray[@]}")
    
    if [ ${#testcaseArray[@]} -eq 0 ]; then
        echo "No testcase found with tag: $tag."
    fi
fi

# config in test_file
skipActionsInMeta=false
groupSetup=()
groupTearDown=()
groupDescription=""

# if testcase is empty then assign from testcaseArray
if [ -z "$testcase" ]; then
    # add testcaseArray into cases
    for case in "${testcaseArray[@]}"; do
        cases+=("$case")
    done
else
    groupPath="$testcase"
    groupJson=$(cat $groupPath)
    skipActionsInMeta=$(jq -r '.skipActionsInMeta' $testcase)
    groupSetup=($(jq -n -r --arg m "$groupJson" '$m' | jq -r '.groupSetup // [] | .[]'))
    groupTearDown=($(jq -n -r --arg m "$groupJson" '$m' | jq -r '.groupTearDown // [] | .[]'))
    groupDescription=$(jq -r '.description' $testcase)
    
    cases=($(jq -r '.files[]' $testcase))
    
    echo "-------Start running test group: $testcase------"
    echo "Skip Actions in Meta: $skipActionsInMeta"
    echo "Group Description: $groupDescription"
    echo "---------------------------------------------"
fi

echo "Cases ${cases[@]}"
if [ ${#cases[@]} -eq 0 ]; then
    echo "No testcase found."
    exit 1
fi

count=0
successed=0
failed=0
initialize_results "$groupDescription" "$testcase" "${#cases[@]}"


# Group SetUp actions
shActionPath="./integration_test/shell_scripts/"
if [ ${#groupSetup[@]} -gt 0 ]; then
    echo "Group Setup: ${groupSetup[@]}"
    for action in "${groupSetup[@]}"; do
        actionPath="$shActionPath$action.sh"
        echo "Group Setup Action: $action"
        bash "$actionPath"
    done
fi

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

    count=$(( $count + 1 ))
    echo "$LINE_BREAK"
    echo "${GREEN} TEST ${count} ${NC}"
    echo "Case Name: $caseName"
    echo "Case Description: $caseDescription"
    echo "Case Path: $casePath"
    echo "$LINE_BREAK"  

    start_test

    # Meta setup actions skip if skipActionsInMeta is true
    if [ ${#caseSetup[@]} -gt 0 ] && [ "$skipActionsInMeta" == false ]; then
        echo "Case Setup: ${caseSetup[@]}"
        for action in "${caseSetup[@]}"; do
            actionPath="$shActionPath$action.sh"
            echo "Case Setup Action: $action"
            bash "$actionPath"
        done
    fi
    
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
        add_success_test "$caseName" "$caseDescription"
        echo "...passed."
    else
        # Failed
        failed=$(( $failed + 1 ))
        # Extract the failure details
        message=$(dart run ./test_scripts/extract_failure_messages.dart "$result")
        echo "$message"
        add_fail_test "$caseName" "$caseDescription" "$message"
        echo "...failed."
        echo "-------------------"
        echo "Result: $result"
        echo "-------------------"
    fi
    echo kill the WiFi detection process
    kill_process
    echo "$LINE_BREAK"

    # Meta teardown actions skip if skipActionsInMeta is true
    if [ ${#caseTearDown[@]} -gt 0 ] && [ "$skipActionsInMeta" == false ]; then
        echo "Case TearDown: ${caseTearDown[@]}"
        for action in "${caseTearDown[@]}"; do
            actionPath="$shActionPath$action.sh"
            echo "Case TearDown Action Path: $actionPath"
            bash "$actionPath" true
        done
    fi
done

# Group TearDown actions
if [ ${#groupTearDown[@]} -gt 0 ]; then
    echo "Group TearDown: ${groupTearDown[@]}"
    for action in "${groupTearDown[@]}"; do
        actionPath="$shActionPath$action.sh"
        echo "Group TearDown Action Path: $actionPath"
        bash "$actionPath" true
    done
fi

add_total_time_cost
cat "$RESULTS_FILE"

sh $root/integration_test/shell_scripts/generate_integration_report.sh

# exit (1) if any failed
if [ "$failed" -gt 0 ]; then
    exit 1
fi
exit 0
#
