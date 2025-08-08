#!/bin/bash

# Define the path for the results JSON file
RESULTS_FILE="./build/integration_test/test_results.json"
TEST_START_TIME=""
START_TIME_EACH_TEST=""
END_TIME_EACH_TEST=""

# --- Function: Initialize the results JSON file ---
# Param 1: Test description (e.g., "UI Dashboard Test")
# Param 2: File path (e.g., "test/dashboard.js")
initialize_results() {
    local description="$1"
    local filePath="$2"
    local totalCount="$3"

    # Use jq to initialize the JSON structure and write to the file
    jq -n --arg d "$description" --arg f "$filePath" --arg t "$totalCount" \
        '{
            "description": $d,
            "filePath": $f,
            "total_count": $t,
            "success": [],
            "fail": []
        }' > "$RESULTS_FILE"
    # Record the start time of the test suite
    TEST_START_TIME=$(date +%s)
}

start_test() {
    START_TIME_EACH_TEST=$(date +%s.%N)
}

# --- Function: Add a successful test case ---
# Param 1: Test name (e.g., "Check dashboard title")
add_success_test() {
    local test_name="$1"
    local test_description="$2"
    
    local end_time_each_test=$(date +%s.%N)

    # Calculate the time cost in seconds with two decimal places using awk
    local test_time_cost=$(awk -v start="$START_TIME_EACH_TEST" -v end="$end_time_each_test" 'BEGIN { printf "%.2f", end - start }')

    # Use jq to update the JSON file
    # Add a new success case object to the success array
    jq --arg n "$test_name" --arg d "$test_description" --arg t "$test_time_cost" \
       '.success += [{"name": $n, "description": $d, "time_cost": $t}]' \
       "$RESULTS_FILE" > "$RESULTS_FILE.tmp" && mv "$RESULTS_FILE.tmp" "$RESULTS_FILE"
}

# --- Function: Add a failed test case ---
# Param 1: Test name (e.g., "Check user profile image")
add_fail_test() {
    local test_name="$1"
    local test_description="$2"
    local error_message="$3"

    local end_time_each_test=$(date +%s.%N)

    # Calculate the time cost in seconds with two decimal places using awk
    local test_time_cost=$(awk -v start="$START_TIME_EACH_TEST" -v end="$end_time_each_test" 'BEGIN { printf "%.2f", end - start }')

    # Use jq to update the JSON file
    # Add a new failed case object to the fail array
    jq --arg n "$test_name" --arg d "$test_description" --arg t "$test_time_cost" --arg e "$error_message" \
       '.fail += [{"name": $n, "description": $d, "time_cost": $t, "error_message": $e}]' \
       "$RESULTS_FILE" > "$RESULTS_FILE.tmp" && mv "$RESULTS_FILE.tmp" "$RESULTS_FILE"
}

# --- Function: Add the total time cost to the JSON file ---
# This function should be called at the very end of your test suite.
add_total_time_cost() {
    if [ -z "$TEST_START_TIME" ]; then
        echo "Error: TEST_START_TIME is not set. Did you call initialize_results()?"
        return 1
    fi

    local end_time=$(date +%s)
    local total_cost=$((end_time - TEST_START_TIME))

    # Use jq to update the total_time_cost field
    jq --argjson cost "$total_cost" \
       '.total_time_cost = $cost' \
       "$RESULTS_FILE" > "$RESULTS_FILE.tmp" && mv "$RESULTS_FILE.tmp" "$RESULTS_FILE"
}