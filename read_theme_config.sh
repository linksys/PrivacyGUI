
# Default value is empty
color=""
# Check if there is an uploaded config file
if [ -f ./theme_config.json ]; then
  # Read the color value from a json file uploaded to the Jenkins workspace
  colorFromJson=$(jq -r '.themeColor' ./theme_config.json)
  # Make sure the color has a value
  if [ -n "$colorFromJson" ]; then
    color="$colorFromJson"
  fi
fi

echo "$color"