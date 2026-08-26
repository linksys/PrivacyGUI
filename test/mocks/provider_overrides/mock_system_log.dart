/// Provider overrides for `usp_system_log_view`.
///
/// Written for #1380 (wave 4) rather than moved out of `test/golden_test/`, because
/// this page has no golden suite — `system_log_scene_data.dart` says what that means
/// for the fixture and why the notifier test's locals were left where they are.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/system_log/models/log_file_ui_model.dart';
import 'package:privacy_gui/page/system_log/providers/usp_system_log_notifier.dart';

import '../test_data/scenes/system_log_scene_data.dart';

/// A `uspSystemLogProvider` pinned to one list of log files.
///
/// The notifier has no mutating methods to stub — the page's only action is an export
/// button that is wired to `null` in `lib` because `Upload()` needs a destination URL
/// — so overriding `build` is the whole mock.
class FixedSystemLogNotifier extends UspSystemLogNotifier {
  final List<LogFileUIModel> _fixedLogFiles;

  FixedSystemLogNotifier(this._fixedLogFiles);

  @override
  Future<List<LogFileUIModel>> build() async => _fixedLogFiles;
}

/// Overrides for `usp_system_log_view`, defaulting to [gateSystemLogState].
List<Override> systemLogOverrides([List<LogFileUIModel>? logFiles]) => [
      uspSystemLogProvider.overrideWith(
        () => FixedSystemLogNotifier(logFiles ?? gateSystemLogState),
      ),
    ];
