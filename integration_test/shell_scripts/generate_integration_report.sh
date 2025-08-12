#!/bin/bash

# Define the JSON input file and the HTML output file
JSON_FILE="./build/integration_test/test_results.json"
HTML_FILE="./build/integration_test/test_report.html"

# Check if the JSON file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: JSON file '$JSON_FILE' not found."
    exit 1
fi

# Use jq to extract data from the JSON file
DESCRIPTION=$(jq -r '.description' "$JSON_FILE")
FILE_PATH=$(jq -r '.filePath' "$JSON_FILE")
TOTAL_COUNT=$(jq -r '.total_count' "$JSON_FILE")
SUCCESS_COUNT=$(jq -r '.success | length' "$JSON_FILE")
FAIL_COUNT=$(jq -r '.fail | length' "$JSON_FILE")
TOTAL_TIME_COST=$(jq -r '.total_time_cost' "$JSON_FILE")

# Extract device information
DEVICE_DESC=$(jq -r '.deviceInfo.description' "$JSON_FILE")
MODEL_NUMBER=$(jq -r '.deviceInfo.modelNumber' "$JSON_FILE")
FIRMWARE_VERSION=$(jq -r '.deviceInfo.firmwareVersion' "$JSON_FILE")
HARDWARE_VERSION=$(jq -r '.deviceInfo.hardwareVersion' "$JSON_FILE")
UI_VERSION=$(jq -r '.deviceInfo.uiVersion' "$JSON_FILE") # 新增：提取 UI 版本

# Generate timestamp for the filename and title
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Create the dynamic HTML filename
HTML_FILE="./build/integration_test/test_report_${MODEL_NUMBER}_${TIMESTAMP}.html"

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
        <p><strong>Total Time Cost:</strong> $TOTAL_TIME_COST seconds</p>

        <div class="device-info">
            <h2>Device Information</h2>
            <p><strong>Description:</strong> $DEVICE_DESC</p>
            <p><strong>Model Number:</strong> $MODEL_NUMBER</p>
            <p><strong>Firmware Version:</strong> $FIRMWARE_VERSION</p>
            <p><strong>Hardware Version:</strong> $HARDWARE_VERSION</p>
            <p><strong>UI Version:</strong> $UI_VERSION</p>
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
$(jq -r '.success[] | "<tr class=\"success-row\"><td>\(.name)</td><td>\(.description)</td><td>\(.time_cost)</td></tr>"' "$JSON_FILE")
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
$(jq -r '.fail[] | "<tr class=\"fail-row\"><td>\(.name)</td><td>\(.description)</td><td>\(.error_message)</td><td>\(.time_cost)</td></tr>"' "$JSON_FILE")
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
EOF

echo "HTML report generated at '$HTML_FILE'."