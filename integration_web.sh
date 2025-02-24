    force="local"
    cloud="qa"
    picker=false
    flutter drive --driver=test_driver/integration_test.dart \
    --target=integration_test/app_test.dart \
    --dart-define=force="${force}" \
    --dart-define=cloud_env="${cloud}" \
    --dart-define=enable_env_picker="${picker}" \
    --browser-name chrome \
    --web-renderer html \
    --web-port 61672 \
    --web-launch-url "https://localhost/" \
    --no-headless \
    --keep-app-running \
    -d web-server

    # flutter run \
    # --dart-define=force="${force}" \
    # --dart-define=cloud_env="${cloud}" \
    # --dart-define=enable_env_picker="${picker}" \
    # --web-renderer html \
    # --web-port 61672 \
    # --web-launch-url "https://localhost/" \
    # -d web-server