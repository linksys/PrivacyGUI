
root="$(dirname "$0")"
config_temp_path="./build/integration_test/temp_config.json"
global_json_path="./build/integration_test/global_config.json"

init_config() {
    local p=$1
    echo "init config path $p"
    local json=$(jq -r '.' "$p")
    result=$?
    path="$p"
    if [[ $result -ne 0 ]]; then
        echo "Config file not found or invalid."
        exit 1
    else
        echo "Config file loaded."
        echo "$json"
        # make sure config_temp_path folder exists
        mkdir -p ./build/integration_test
        # export data_json to config_temp_path
        echo "$json" > "$config_temp_path"
        echo "export data_json to temp_config.json file"
    fi
}

# parameter 2 - either a json file path or a json string
set_config() {
    new_json_path=$1
    # join new json into config_temp_path
    merge_json_to_key "$config_temp_path" "$new_json_path"
    echo "Set new json into temp_config.json file"
    echo "$(get_config_value .)"
}

merge_json_to_key() {
  local base_file="$1"
  local merge_file="$2"
  local output_file="$1"

  # Check if jq is installed
  if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it to use this function."
    return 1
  fi

  # Check if base file exists
  if [[ ! -f "$base_file" ]]; then
    echo "Error: Base JSON file '$base_file' not found."
    return 1
  fi


  # Check if merge file exists or merge file is json string
  local merged_from_json=false
  if [[ -z "$merge_file" ]]; then
    echo "Error: Merge JSON (file) is empty"
  else
    test_json=$(echo "$merge_file" | jq -e '.')
    test_result=$?
    if [[ $test_result -ne 0 ]]; then
      echo "Error: Merge JSON file '$merge_file' not found or invalid JSON string."
      return 1
    else
      echo "Merge JSON string is valid."
      merged_from_json=true
    fi
  fi

  # Read JSON files into shell variables
  local base_json=$(cat "$base_file")
  # check if merged from json

  local merge_json=""
  if [[ "$merged_from_json" == "true" ]]; then
    merge_json="$merge_file"
  else
    merge_json=$(cat "$merge_file")
  fi
  

  # Merge the JSON using jq (compatible with older versions)
  local merged_json=$(jq -n --argjson base "$base_json" --argjson merge "$merge_json" '($base + $merge)')

  # Check if jq command was successful
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to merge JSON files using jq."
    return 1
  fi

  # Write the merged JSON to the output file
  echo "$merged_json" > "$output_file"

  # Check if writing to the output file was successful
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to write merged JSON to '$output_file'."
    return 1
  fi

  echo "Successfully merged '$merge_file' (output in '$output_file')."
  return 0
}

remove_config() {
    # remove key from config_temp_path
    local key=$1
    if [ -z "$key" ]; then
        key="merged"
    fi
    json=$(cat $config_temp_path)
    # remove key from json
    local new_json=$(jq "del(.$key)" <<< "$json")
    # write new json to config_temp_path
    echo "$new_json" > "$config_temp_path"
    echo "Removed key <$key> from temp config file."
}

clean_config() {
    # remove json file from config_temp_path
    if [ -f "$config_temp_path" ]; then
        rm "$config_temp_path"
        echo "Removed temp config file."
    fi
    
}

get_config_value() {
    # pass selector if not put .
    local selector=$1
    if [ -z "$selector" ]; then
        echo "No selector passed"
        exit 1
    fi
    # get value from config_temp_path
    json=$(cat $config_temp_path)
    # get value from json
    local value=$(jq -r "$selector" <<< "$json")
    if [[ $value == "null" ]]; then
        echo "No such key found. <$selector>"
        exit 1
    else
        echo "$value"
    fi
    
}

set_global_config() {
    local p=$1
    echo "set global config from $p"
    local json=$(jq -r '.' "$p")
    result=$?
    path="$p"
    if [[ $result -ne 0 ]]; then
        echo "Global Config file not found or invalid."
        exit 1
    else
        echo "Global Config file loaded."
        echo "$json"
        # make sure config_temp_path folder exists
        mkdir -p ./build/integration_test
        # export data_json to config_temp_path
        echo "$json" > "$global_json_path"
        echo "export global config to $global_json_path"
    fi
}

get_global_config_value() {
  # pass selector if not put .
  local selector=$1
  if [ -z "$selector" ]; then
      echo "No selector passed"
      exit 1
  fi
  # get value from config_temp_path
  json=$(cat $global_json_path)
  # get value from json
  local value=$(jq -r "$selector" <<< "$json")
  if [[ $value == "null" ]]; then
      echo "No such key found. <$selector>"
      exit 1
  else
      echo "$value"
  fi
    
}