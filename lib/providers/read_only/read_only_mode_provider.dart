import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';

/// Whether this build is read-only.
///
/// Fixed per build by [BuildConfig.readOnly]. It is a provider only so the
/// read-only paths can be exercised in an ordinary test run, which is compiled
/// without the define; nothing in the app ever changes it.
final readOnlyModeProvider = Provider<bool>((ref) => BuildConfig.readOnly);
