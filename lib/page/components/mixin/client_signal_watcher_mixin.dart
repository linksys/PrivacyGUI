import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';

/// For a page that shows client signal strength: refreshes it on entry, and on
/// every poll tick for as long as the page is mounted.
///
/// Every refresh goes through [PollingNotifier.refreshClientSignals], so its
/// cooldown holds however many of these pages are stacked.
mixin ClientSignalWatcherMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  // Held rather than looked up again in dispose(), where ref may no longer be
  // used.
  late final PollingNotifier _polling;

  bool _watching = false;

  /// Whether this page shows client signal strength right now. A page that only
  /// sometimes does - a device detail page on a wired client - says no here and
  /// costs the mesh nothing; one whose answer can change calls
  /// [updateClientSignalWatch] when it does.
  bool get watchesClientSignals => true;

  @override
  void initState() {
    super.initState();
    _polling = ref.read(pollingProvider.notifier);
    updateClientSignalWatch();
  }

  /// Starts or stops watching to match [watchesClientSignals]. Starting refreshes
  /// at once, cooldown permitting.
  void updateClientSignalWatch() {
    final wanted = watchesClientSignals;
    if (wanted == _watching) {
      return;
    }
    _watching = wanted;
    if (wanted) {
      _polling.watchClientSignals();
      _polling.refreshClientSignals();
    } else {
      _polling.unwatchClientSignals();
    }
  }

  @override
  void dispose() {
    if (_watching) {
      _polling.unwatchClientSignals();
    }
    super.dispose();
  }
}
