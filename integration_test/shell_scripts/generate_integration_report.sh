#!/bin/bash

# Define the JSON input file
JSON_FILE="./build/integration_test/test_results.json"

# Check if the JSON file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: JSON file '$JSON_FILE' not found."
    exit 1
fi

# --- Function: Convert seconds to HH:mm:ss format ---
format_seconds() {
  local total_seconds=$1
  
  # Use bc to handle floating-point arithmetic
  if (( $(echo "$total_seconds < 0" | bc -l) )); then
    echo "00:00:00"
    return
  fi
  
  # Convert to integer for format calculation
  local int_seconds=$(echo "$total_seconds / 1" | bc)
  
  local hours=$((int_seconds / 3600))
  local minutes=$(( (int_seconds % 3600) / 60 ))
  local seconds=$(( int_seconds % 60 ))
  printf "%02d:%02d:%02d\n" $hours $minutes $seconds
}

# Use jq to extract data from the JSON file
DESCRIPTION=$(jq -r '.description' "$JSON_FILE")
FILE_PATH=$(jq -r '.filePath' "$JSON_FILE")
TOTAL_COUNT=$(jq -r '.total_count' "$JSON_FILE")
SUCCESS_COUNT=$(jq -r '.success | length' "$JSON_FILE")
FAIL_COUNT=$(jq -r '.fail | length' "$JSON_FILE")
TOTAL_TIME_COST=$(jq -r '.total_time_cost' "$JSON_FILE")
WIRED_STATUS=$(jq -r '.deviceInfo.wired' "$JSON_FILE")

# Extract device information
DEVICE_DESC=$(jq -r '.deviceInfo.description' "$JSON_FILE")
MODEL_NUMBER=$(jq -r '.deviceInfo.modelNumber' "$JSON_FILE")
FIRMWARE_VERSION=$(jq -r '.deviceInfo.firmwareVersion' "$JSON_FILE")
HARDWARE_VERSION=$(jq -r '.deviceInfo.hardwareVersion' "$JSON_FILE")
UI_VERSION=$(jq -r '.deviceInfo.uiVersion' "$JSON_FILE")

# --- 從 JSON 檔案中讀取 timestamp ---
TIMESTAMP_RAW=$(jq -r '.timestamp' "$JSON_FILE")
echo "TIMESTAMP_RAW: $TIMESTAMP_RAW"
if [[ "$TIMESTAMP_RAW" =~ ^[0-9]+$ ]]; then
    SECONDS_EPOCH=$(echo "$TIMESTAMP_RAW" | bc)
    
    TIMESTAMP=$(date -r "$SECONDS_EPOCH" +"%Y-%m-%d_%H-%M-%S")
    echo "TIMESTAMP: $TIMESTAMP"
else
    echo "Warning: 'timestamp' key not found or is not a millisecond timestamp. Using current time as fallback." >&2
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
fi

# Create the dynamic HTML filename
HTML_FILE="./build/integration_test/test_report_${MODEL_NUMBER}_${TIMESTAMP}.html"

# Determine connection type based on wired status
if [[ "$WIRED_STATUS" == "true" ]]; then
    CONNECTION_TYPE="Wired"
else
    CONNECTION_TYPE="Wireless"
fi

# --- Format Total Time Cost ---
TOTAL_TIME_COST_FORMATTED=$(format_seconds "$TOTAL_TIME_COST")

# --- Success Cases ---
SUCCESS_ROWS=$(jq -c '.success[]' "$JSON_FILE" | while IFS= read -r line; do
  test_name=$(echo "$line" | jq -r '.name')
  description=$(echo "$line" | jq -r '.description')
  time_cost=$(echo "$line" | jq -r '.time_cost')
  formatted_time_cost=$(format_seconds "$time_cost")
  printf "<tr class=\"success-row\"><td>%s</td><td>%s</td><td>%s</td></tr>\n" "$test_name" "$description" "$formatted_time_cost"
done)

# --- Fail Cases ---
FAIL_ROWS=$(jq -c '.fail[]' "$JSON_FILE" | while IFS= read -r line; do
  test_name=$(echo "$line" | jq -r '.name')
  description=$(echo "$line" | jq -r '.description')
  error_message=$(echo "$line" | jq -r '.error_message')
  time_cost=$(echo "$line" | jq -r '.time_cost')
  formatted_time_cost=$(format_seconds "$time_cost")
  printf "<tr class=\"fail-row\"><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n" "$test_name" "$description" "$error_message" "$formatted_time_cost"
done)

# Generate the HTML file using a 'here document'
cat > "$HTML_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${MODEL_NUMBER} Test Report - ${TIMESTAMP}</title>
    <style>
        body { font-family: sans-serif; margin: 2rem; background-color: #f4f4f9; color: #333; }
        .container { max-width: 900px; margin: auto; background: #fff; padding: 2rem; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 0.5rem; }
        h2 { border-left: 4px solid #3498db; padding-left: 1rem; color: #34495e; margin-top: 2rem; }
        .summary-box { display: flex; justify-content: space-between; margin-bottom: 2rem; }
        .summary-item { flex: 1; text-align: center; padding: 1rem; border-radius: 8px; margin: 0 0.5rem; color: #fff; }
        .summary-item.success { background-color: #2ecc71; }
        .summary-item.fail { background-color: #e74c3c; }
        .summary-item.total { background-color: #3498db; }
        .test-results { margin-top: 2rem; }
        table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
        th, td { padding: 12px; border: 1px solid #ddd; text-align: left; }
        th { background-color: #f2f2f2; }
        tr.success-row { background-color: #e8f5e9; }
        tr.fail-row { background-color: #ffebee; }
    </style>
</head>
<body>
    <div class="container">
        <h1>${MODEL_NUMBER} Test Report - ${TIMESTAMP}</h1>
        <p><strong>Description:</strong> $DESCRIPTION</p>
        <p><strong>File Path:</strong> $FILE_PATH</p>
        <p><strong>Total Time Cost:</strong> $TOTAL_TIME_COST_FORMATTED</p>

        <div class="device-info">
            <h2>Device Information</h2>
            <p><strong>Description:</strong> $DEVICE_DESC</p>
            <p><strong>Model Number:</strong> $MODEL_NUMBER</p>
            <p><strong>Firmware Version:</strong> $FIRMWARE_VERSION</p>
            <p><strong>Hardware Version:</strong> $HARDWARE_VERSION</p>
            <p><strong>UI Version:</strong> $UI_VERSION</p>
            <p><strong>Connection:</strong> $CONNECTION_TYPE</p>
        </div>

        <hr style="margin: 2rem 0;">

        <div class="summary-box">
            <div class="summary-item total">Total: $TOTAL_COUNT</div>
            <div class="summary-item success">Success: $SUCCESS_COUNT</div>
            <div class="summary-item fail">Fail: $FAIL_COUNT</div>
        </div>

        <div class="test-results">
            <h2>Success Cases</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Description</th>
                        <th>Time Cost (s)</th>
                    </tr>
                </thead>
                <tbody>
$SUCCESS_ROWS
                </tbody>
            </table>
        </div>

        <div class="test-results">
            <h2>Failed Cases</h2>
            <table>
                <thead>
                    <tr>
                        <th>Test Name</th>
                        <th>Description</th>
                        <th>Error Message</th>
                        <th>Time Cost (s)</th>
                    </tr>
                </thead>
                <tbody>
$FAIL_ROWS
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
EOF

echo "HTML report generated at '$HTML_FILE'."
