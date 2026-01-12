/// Dashboard home components barrel file.
library;

export 'settings/dashboard_layout_settings_panel.dart';
export 'core/dashboard_loading_wrapper.dart';
export 'core/dashboard_tile.dart';
export 'core/display_mode_widget.dart';
export 'dialogs/firmware_update_countdown_dialog.dart';
export 'core/loading_tile.dart';

// Shared parts
export 'widgets/parts/external_speed_test_links.dart';
export 'widgets/parts/internal_speed_test_result.dart';
export 'widgets/parts/port_status_widget.dart';
export 'widgets/parts/remote_assistance_animation.dart';
export 'widgets/parts/wifi_card.dart';

// Shared widgets
export 'widgets/home_title.dart';

// Composite widgets (for fixed layouts)
export 'widgets/composite/internet_status.dart';
export 'widgets/composite/networks.dart';
export 'widgets/composite/port_and_speed.dart';
export 'widgets/composite/quick_panel.dart';
export 'widgets/composite/wifi_grid.dart';

// Atomic widgets (for custom layout / Bento Grid)
export 'widgets/atomic/internet_status_only.dart'; // CustomInternetStatus
export 'widgets/atomic/master_node_info.dart';
export 'widgets/atomic/ports.dart';
export 'widgets/atomic/speed_test.dart';
export 'widgets/atomic/network_stats.dart';
export 'widgets/atomic/topology.dart'; // CustomTopology
export 'widgets/atomic/custom_wifi_grid.dart';
export 'widgets/atomic/custom_quick_panel.dart';
