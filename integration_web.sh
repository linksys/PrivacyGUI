force="local"
cloud="qa"
picker=false

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
password="?p=$p"
if [ -z "$p" ]; then
    password=""
fi

count=0
cases=($(jq -r '.files[]' $testcase))
flutter pub get
for case in "${cases[@]}"; do
    count=$(( $count + 1 ))
    echo "$LINE_BREAK"
    echo "${GREEN} TEST ${count} ${NC}"
    echo "$LINE_BREAK"  
    
    echo "Test file: $case"
    flutter drive --driver=test_driver/integration_test.dart \
    --target=$case \
    --dart-define=force="${force}" \
    --dart-define=cloud_env="${cloud}" \
    --dart-define=enable_env_picker="${picker}" \
    --dart-define-from-file=$data \
    --no-pub \
    --browser-name chrome \
    --web-renderer html \
    --web-port 61672 \
    --web-launch-url "https://localhost/$password" \
    --no-headless \
    --keep-app-running \
    -d web-server
done
