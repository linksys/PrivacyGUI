// UI Models exports
export 'internet_settings_ui_model.dart';
export 'ipv4_settings_ui_model.dart';
export 'ipv6_settings_ui_model.dart';
export 'supported_wan_combination_ui_model.dart';
export 'internet_settings_enums.dart';

// Type aliases for backward compatibility during migration
// These will be removed after all files are updated
import 'ipv4_settings_ui_model.dart';
import 'ipv6_settings_ui_model.dart';
import 'internet_settings_ui_model.dart';
import 'supported_wan_combination_ui_model.dart';

typedef Ipv4Setting = Ipv4SettingsUIModel;
typedef Ipv6Setting = Ipv6SettingsUIModel;
typedef InternetSettings = InternetSettingsUIModel;
typedef InternetSettingsStatus = InternetSettingsStatusUIModel;
typedef SupportedWANCombination = SupportedWANCombinationUIModel;
