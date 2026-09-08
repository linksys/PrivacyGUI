import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/core/utils/fernet_manager.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';

const int pollFirstDelayInSec = 1;

/// How long after a failed poll to ask the router again, instead of waiting out
/// the whole [BuildConfig.refreshTimeInterval].
///
/// Short on purpose: it is what lets a router that was away for a moment prove
/// it is back before anybody is told it is gone.
const int pollRetryDelayInSec = 5;

/// How long the router may go without answering a poll before it counts as
/// unreachable.
///
/// Measured in time rather than in failed polls because the two failure modes
/// this has to cover are eight times apart: a refused connection fails at once
/// and gets no retry from the HTTP client (only a TimeoutException does), while
/// a timeout takes the request's full 10s twice over. Counting failures would
/// put the alert 4s into a router restarting its HTTP service - the very blip it
/// must not fire on - and 46s into an unplugged one.
const int pollUnreachableAfterInSec = 20;

final pollingProvider =
    AsyncNotifierProvider<PollingNotifier, CoreTransactionData>(
        () => PollingNotifier());

/// How many polls have found the router silent for longer than
/// [pollUnreachableAfterInSec] - 0 for as long as it is answering.
///
/// The signal for 'the router has gone away', which nothing else reports: every
/// *deliberate* disappearance (a save with a DeviceRestart side effect, a reboot,
/// a firmware update) is announced by the flow that caused it, and a failing
/// background poll used to be announced by nobody. [pollingProvider] itself
/// cannot carry this: a failed poll leaves it in [AsyncError], and Riverpod
/// hands an AsyncError the *previous* value, so anything written into
/// [CoreTransactionData] on the way to an error would never be read.
///
/// Anything above zero means unreachable; the number itself matters only so that
/// a report is not a one-off. A report landing while a route that raises the
/// alert itself is up has to be dropped, and a count lets the next failed poll
/// raise it again once that route is gone - which a settled flag could not.
final routerUnreachableProvider = StateProvider<int>((ref) => 0);

class CoreTransactionData extends Equatable {
  final int lastUpdate;
  final bool isReady;
  final Map<JNAPAction, JNAPResult> data;

  const CoreTransactionData({
    required this.lastUpdate,
    required this.isReady,
    required this.data,
  });

  @override
  List<Object> get props => [lastUpdate, isReady, data];

  CoreTransactionData copyWith({
    int? lastUpdate,
    bool? isReady,
    Map<JNAPAction, JNAPResult>? data,
  }) {
    return CoreTransactionData(
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isReady: isReady ?? this.isReady,
      data: data ?? this.data,
    );
  }
}

class PollingNotifier extends AsyncNotifier<CoreTransactionData> {
  static Timer? _timer;

  /// Bumped by every [stopPolling], so a start-up sequence already in flight can
  /// tell that it has been called off.
  ///
  /// The timer is the only thing [stopPolling] can cancel outright; the sequence
  /// that installs it runs for a second or more before that and has to check for
  /// itself. Static like [_timer], since the notifier can be rebuilt under a
  /// timer that is still running.
  static int _generation = 0;

  /// The short re-poll a failure earns, or null while the router is answering.
  /// Static for the same reason as [_timer].
  static Timer? _retryTimer;

  /// Runs out once the router has been silent for [pollUnreachableAfterInSec].
  /// Static for the same reason as [_timer].
  ///
  /// Armed when a poll goes out rather than when one fails, which is what makes
  /// the deadline independent of how long a failure takes to happen - see
  /// [pollUnreachableAfterInSec].
  static Timer? _silenceDeadline;

  /// Whether [_silenceDeadline] has run out.
  ///
  /// Kept, rather than reported on the spot, because the deadline can run out
  /// while a poll is still on the wire: the router has been silent that long
  /// either way, but it is that poll coming back empty that settles it.
  static bool _silenceDeadlinePassed = false;

  /// Whether the last poll to come back did so empty-handed.
  static bool _pollFailing = false;

  bool _paused = false;
  set paused(bool value) {
    _paused = value;
    if (_paused) {
      _timer?.cancel();
      _retryTimer?.cancel();
      _silenceDeadline?.cancel();
      _silenceDeadline = null;
    } else {
      checkAndStartPolling();
    }
  }

  bool get paused => _paused;

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _coreTransactions = [];

  /// The mode the router last reported, or null while it has never answered.
  ///
  /// Worth remembering because [checkSmartMode] is allowed to fail: falling all
  /// the way back to 'Unconfigured' builds the command set without
  /// getBackhaulInfo, which would quietly strip backhaul data from every poll of
  /// a Master for the rest of the session over one lost request.
  String? _lastKnownMode;

  /// How many later polls may still re-read a device mode the router has never
  /// given.
  ///
  /// Bounded because that re-read repairs a *transient* failure. A router that
  /// keeps refusing getDeviceMode would otherwise add the request's full timeout
  /// to every tick and every pull-to-refresh for the rest of the session, to fix
  /// nothing.
  static const int _maxModeRetries = 3;
  int _modeRetriesLeft = _maxModeRetries;

  @override
  FutureOr<CoreTransactionData> build() {
    return const CoreTransactionData(lastUpdate: 0, isReady: false, data: {});
  }

  init() {
    // Called on logout, so the next login may well be to a different router:
    // forget the mode rather than let it stand in as a fallback for one whose
    // own read failed, and give the new router its own repair budget.
    _lastKnownMode = null;
    _modeRetriesLeft = _maxModeRetries;
    _clearRouterSilence();
    state = AsyncValue.data(
        const CoreTransactionData(lastUpdate: 0, isReady: false, data: {}));
  }

  fetchFirstLaunchedCacheData() {
    final cache = ref.read(linksysCacheManagerProvider).data;
    final commands = _coreTransactions;
    final checkCacheDataList = commands
        .where((command) => cache.keys.contains(command.key.actionValue));
    // Have not done any polling yet
    if (checkCacheDataList.length != commands.length) return;

    final cacheDataList = checkCacheDataList
        .where((command) => cache[command.key.actionValue]['data'] != null)
        .map((command) => MapEntry(command.key,
            JNAPSuccess.fromJson(cache[command.key.actionValue]['data'])))
        .toList();

    // Update Fernet key from cached device info
    try {
      final deviceInfoEntry = cacheDataList.firstWhere(
        (entry) => entry.key == JNAPAction.getDeviceInfo,
      );
      final deviceInfoResult = deviceInfoEntry.value;

      final serialNumber = deviceInfoResult.output['serialNumber'] as String?;
      if (serialNumber != null && serialNumber.isNotEmpty) {
        FernetManager().updateKeyFromSerial(serialNumber);
        logger.d('Fernet key updated from cached serial number.');
      }
    } catch (e) {
      // Could be a StateError if not found, or other errors.
      logger.i('Device info not found in cache, cannot update Fernet key yet.');
    }

    final previousSnapshot = state.value;
    state = AsyncValue.data(CoreTransactionData(
        lastUpdate: 0,
        isReady: previousSnapshot?.isReady ?? false,
        data: Map.fromEntries(cacheDataList)));
  }

  Future _polling(RouterRepository repository, {bool force = false}) async {
    // Whose poll this is. Read before the first await, because by the time an
    // answer comes back - or fails to - polling may have been stopped on purpose,
    // and this poll then speaks for a router nobody is watching any more.
    final generation = _generation;

    // Repair a start-up whose device-mode read failed, rather than polling in a
    // degraded shape until the next login. Once the router has answered once,
    // neither branch runs again.
    if (_coreTransactions.isEmpty) {
      // Nothing to ask the router at all. This is the state every forcePolling
      // was stuck in - pull-to-refresh, the refresh after saving a setting - so
      // no amount of refreshing could repopulate the dashboard. Building a
      // command set always succeeds, so this runs at most once.
      await _resolveCoreTransaction();
    } else if (_lastKnownMode == null && _modeRetriesLeft > 0) {
      // The set was built, but without getBackhaulInfo, because the mode was
      // unknown when it was built. See [_maxModeRetries] for why this is counted.
      _modeRetriesLeft--;
      await _resolveCoreTransaction();
    }

    // Starts the clock on the router's silence, before the request that may go
    // unanswered rather than after it has given up.
    _armSilenceDeadline();

    final benchMark = BenchMarkLogger(name: 'Polling provider');
    benchMark.start();
    final previousSnapshot = state.value;
    state = const AsyncValue.loading();
    final fetchFuture = repository
        .transaction(
          JNAPTransactionBuilder(commands: _coreTransactions, auth: true),
          fetchRemote: force,
        )
        .then((successWrap) => successWrap.data)
        .then((data) => CoreTransactionData(
              lastUpdate: DateTime.now().millisecondsSinceEpoch,
              isReady: previousSnapshot?.isReady ?? false,
              data: Map.fromEntries(data),
            ))
        .onError((error, stackTrace) {
      logger.e('Polling error: $error, $stackTrace');
      // Only a rejected credential justifies logging the user out. A single
      // failed poll used to do it, so anything that briefly took the router's
      // HTTP service away - a service restart, the make-Master credential
      // rotation - kicked the user back to the login page even though their
      // password was still good. Leave the state in error and let the next
      // poll tick recover.
      if (_isAuthFailure(error)) {
        logger.f('[Auth]: Force to log out: the router refused the credential '
            'with ${(error as JNAPError).result}');
        ref.read(authProvider.notifier).logout();
      }

      throw error ?? '';
    });

    final result = await AsyncValue.guard(
      () => fetchFuture.then(
        (result) async {
          // Update Fernet key from device info
          try {
            final deviceInfoResult = result.data[JNAPAction.getDeviceInfo];
            if (deviceInfoResult is JNAPSuccess) {
              final serialNumber =
                  deviceInfoResult.output['serialNumber'] as String?;
              if (serialNumber != null && serialNumber.isNotEmpty) {
                FernetManager().updateKeyFromSerial(serialNumber);
              } else {
                logger.w(
                    'Serial number not found in getDeviceInfo response, cannot update Fernet key.');
              }
            }
          } catch (e) {
            logger.e('Failed to update Fernet key: $e');
          }

          await _additionalPolling();
          return result.copyWith(isReady: true);
        },
      ).onError((e, stackTrace) {
        logger.e('Polling error: $e, $stackTrace');
        throw e ?? '';
      }),
    );
    state = result;
    // A poll that outlived the reason it was started says nothing about the
    // router: the flow that stopped polling is the one taking the router away,
    // and it tells the operator so itself.
    if (!_isCancelled(generation)) {
      // Only a poll that got no answer at all counts towards the router's
      // silence. A JNAPError is an answer - the router is there and talking - so
      // it is neither unreachable nor owed the short re-poll that silence earns.
      // In the case that matters most, that re-poll would cost the operator
      // something: the router locks the admin account after a handful of refused
      // credentials ([errorAdminAccountLocked]), and LinksysHttpClient retries a
      // 401 once, so a single unauthorized poll already spends two attempts.
      // Asking again every [pollRetryDelayInSec] is how a password that went
      // stale becomes an account nobody can log into.
      if (!result.hasError || result.error is JNAPError) {
        _clearRouterSilence();
      } else {
        _recordPollFailure(repository);
      }
    }

    benchMark.end();
  }

  /// Starts the clock on the router's silence, unless it is already running.
  ///
  /// Anchored at the moment a poll goes out, not at the moment one gives up:
  /// what the operator needs to hear about is how long the router has been quiet,
  /// and anchoring it to a failure would report the HTTP client's timeout policy
  /// instead. See [pollUnreachableAfterInSec].
  void _armSilenceDeadline() {
    if (_silenceDeadline != null || _silenceDeadlinePassed) {
      return;
    }
    _silenceDeadline =
        Timer(const Duration(seconds: pollUnreachableAfterInSec), () {
      _silenceDeadline = null;
      _silenceDeadlinePassed = true;
      // A deadline that runs out while a poll is still on the wire waits for
      // that poll: see [_silenceDeadlinePassed].
      if (_pollFailing) {
        _reportRouterUnreachable();
      }
    });
  }

  /// Notes a failed poll, and either reports the router unreachable or gives it
  /// another chance to answer shortly.
  ///
  /// Failing quietly is what made #1419: the provider keeps its previous value
  /// through an [AsyncError], so every consumer goes on drawing the last good
  /// snapshot and nothing on screen says the router stopped answering.
  ///
  /// The short re-polls are what keep the report honest. Waiting out the whole
  /// [BuildConfig.refreshTimeInterval] between attempts would mean a router that
  /// came back ten seconds in still got reported unreachable at twenty, because
  /// nothing had asked it since.
  void _recordPollFailure(RouterRepository repository) {
    _pollFailing = true;
    if (_silenceDeadlinePassed) {
      // Long enough, and this poll is the proof. From here the periodic tick is
      // enough on its own - re-polling every few seconds behind a dialog that is
      // already up would just pile up requests.
      _reportRouterUnreachable();
      return;
    }
    // No cancellation check in the callback: everything that stops or pauses
    // polling cancels this timer outright, so a fired callback is by construction
    // one nobody called off. [_polling] re-checks anyway for the answer it is
    // still waiting on.
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: pollRetryDelayInSec),
        () => _polling(repository));
  }

  void _reportRouterUnreachable() {
    logger.i('[RouterNotFound] no answer for ${pollUnreachableAfterInSec}s');
    ref.read(routerUnreachableProvider.notifier).state =
        ref.read(routerUnreachableProvider) + 1;
  }

  /// Puts everything about a router that was not answering back to how it looks
  /// when one is.
  void _clearRouterSilence() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _silenceDeadline?.cancel();
    _silenceDeadline = null;
    _silenceDeadlinePassed = false;
    _pollFailing = false;
    ref.read(routerUnreachableProvider.notifier).state = 0;
  }

  /// Whether the run that started in [generation] is still the one anybody is
  /// waiting on.
  ///
  /// Everything that takes the router away deliberately - a logout, a save with a
  /// DeviceRestart side effect, a firmware update, PnP - either stops polling or
  /// pauses it. Anything still in flight across that boundary has to notice, or it
  /// polls a router nobody is watching and reports on its silence.
  bool _isCancelled(int generation) => _paused || generation != _generation;

  /// Whether the router rejected our credential, as opposed to never having
  /// answered. Only the former means the session is really gone.
  ///
  /// Acted on the first time it happens, and deliberately so: the router locks
  /// the admin account after a handful of refused credentials
  /// ([errorAdminAccountLocked]), and LinksysHttpClient retries a 401 once, so
  /// every poll that carries a rejected one spends two of the operator's
  /// attempts. Tolerating a few before logging out would trade a session they can
  /// get back for an account they have to wait out.
  ///
  /// [errorAdminAccountLocked] is the same verdict one step further along: the
  /// attempts have already run out, so the credential is not merely wrong, it
  /// will not be looked at again until the lockout expires. Polling on with it
  /// keeps feeding the very counter that has to run down, and leaves the operator
  /// in front of a dashboard that has quietly stopped updating with nothing to
  /// say why. Logging out puts them on the login page, whose own
  /// getAdminPasswordAuthStatus probe is what reports the lockout and counts it
  /// down.
  ///
  /// Cloud-side session invalidation is not checked here on purpose:
  /// [LinksysHttpClient.onError] already routes `INVALID_SESSION_TOKEN` through
  /// [AuthNotifier], which re-checks the session token before logging out.
  bool _isAuthFailure(Object? error) =>
      error is JNAPError &&
      (error.result == errorJNAPUnauthorized ||
          error.result == errorAdminAccountLocked);

  Future _additionalPolling() async {
    if (serviceHelper.isSupportLedMode()) {
      await ref.read(nodeLightSettingsProvider.notifier).fetch();
    }
    if (serviceHelper.isSupportVPN()) {
      await ref.read(vpnProvider.notifier).fetch(false, true);
    }

    await ref.read(instantPrivacyProvider.notifier).fetch(statusOnly: true);

    final loginType = ref.read(authProvider).value?.loginType;
    // TODO: Disable remote assistance for now
    // logger.i('[Polling]: _additionalPolling loginType: $loginType');
    // if (loginType == LoginType.local) {
    //   logger.i('[Polling]: checking active remote session');
    //   await ref.read(remoteClientProvider.notifier).checkActiveSession();
    // }
  }

  Future forcePolling() async {
    // Same reason [_runStartupSequence] takes a generation: the timer install is
    // on the far side of an await, so a stopPolling() that lands while the forced
    // poll is on the wire would be undone here. A logout is the worst of those -
    // polling would resume with no credential, and the first _ErrorUnauthorized
    // would force another logout - but a reboot is the likelier one: a
    // pull-to-refresh still in flight when the operator restarts the router would
    // put the timer back, and the ticks that followed would report the router
    // unreachable over the restart's own progress dialog.
    final generation = _generation;
    final routerRepository = ref.read(routerRepositoryProvider);

    await _polling(routerRepository, force: true);
    if (_isCancelled(generation)) {
      logger
          .d('polling was called off during a forced poll, no timer installed');
      return;
    }
    _setTimePeriod(routerRepository);
  }

  void checkAndStartPolling([bool force = false]) {
    final loginType = ref.read(authProvider).value?.loginType;
    if (loginType == LoginType.none) {
      return;
    }
    if (!force && (_timer?.isActive ?? false)) {
      return;
    } else {
      _paused = false;
      stopPolling();
      startPolling();
    }
  }

  startPolling() {
    if (_paused) {
      return;
    }
    logger.d('prepare start polling data');
    // Deliberately neither awaited nor returned: callers chain off this call
    // (PowerTableNotifier.save) and must not be made to wait out the first poll.
    _runStartupSequence(ref.read(routerRepositoryProvider));
  }

  /// Reads the device mode, seeds from cache, polls once, then installs the
  /// periodic timer.
  ///
  /// Every step before that last one is best-effort. This used to be an
  /// unguarded `.then` chain hanging off [checkSmartMode], so one refused socket
  /// - a router restarting its HTTP service, a connection dropped on the way into
  /// the dashboard - skipped both the command-set build and the timer install.
  /// The caller has already cancelled the previous timer by then
  /// (PrepareDashboardView stops before it starts), so polling stopped for good
  /// and silently: the dashboard kept showing cached values and only a re-login
  /// brought it back. The timer is what lets a later tick recover, so it goes in
  /// no matter what any single step did.
  Future<void> _runStartupSequence(RouterRepository routerRepository) async {
    // Guaranteeing the timer install means this sequence must not outlive the
    // reason it was started: a logout or a DeviceRestart side effect that lands
    // while it is still running would otherwise have its stopPolling() undone
    // here, and polling would resume against a rebooting router or with no
    // credential at all. The generation is what makes those stops stick.
    final generation = _generation;
    bool cancelled() => _isCancelled(generation);

    _modeRetriesLeft = _maxModeRetries;
    // A fresh session makes no claim about this router yet, and this is the
    // recovery path the router-not-found alert's own Try again button runs: a
    // report that survived it would put the alert straight back up.
    _clearRouterSilence();
    try {
      await _resolveCoreTransaction();
      if (cancelled()) return;
      fetchFirstLaunchedCacheData();
      await Future.delayed(const Duration(seconds: pollFirstDelayInSec));
      if (cancelled()) return;
      await _polling(routerRepository);
    } catch (e, stackTrace) {
      logger.e('Polling start-up failed, installing the timer anyway: '
          '$e, $stackTrace');
    }
    if (cancelled()) {
      logger.d('polling was called off during start-up, no timer installed');
      return;
    }
    _setTimePeriod(routerRepository);
  }

  /// Rebuilds the poll's command set from the router's current device mode.
  Future<void> _resolveCoreTransaction() async {
    _coreTransactions = _buildCoreTransaction(mode: await checkSmartMode());
  }

  stopPolling() {
    logger.d('stop polling data');
    // Calls off any start-up sequence still on its way to installing a timer, as
    // well as cancelling the one that is already running.
    _generation++;
    if ((_timer?.isActive ?? false)) {
      _timer?.cancel();
    }
    // The re-poll a failed poll left behind would otherwise ask a router nobody
    // is waiting on any more, and count its silence against it. The deadline goes
    // for the same reason: whatever stopped polling is taking the router away on
    // purpose and reports that itself.
    _retryTimer?.cancel();
    _retryTimer = null;
    _silenceDeadline?.cancel();
    _silenceDeadline = null;
    // And the reckoning along with them, so that whatever polls next is judged on
    // its own silence rather than on the run that was called off. Not
    // hypothetical: a node reboot stops polling and then forces a single poll of
    // its own with no startPolling in between (InstantTopologyView._doReboot), and
    // a window left standing as already used up would have that poll reported the
    // moment it failed - over the reboot's own progress dialog. The report itself
    // is left alone: a stop is not the router coming back.
    _silenceDeadlinePassed = false;
    _pollFailing = false;
  }

  _setTimePeriod(RouterRepository routerRepository) {
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(seconds: BuildConfig.refreshTimeInterval), (timer) {
      _polling(routerRepository);
    });
  }

  List<MapEntry<JNAPAction, Map<String, dynamic>>> _buildCoreTransaction(
      {String? mode}) {
    final isSupportGuestWiFi = serviceHelper.isSupportGuestNetwork();

    List<MapEntry<JNAPAction, Map<String, dynamic>>> commands = [
      const MapEntry(JNAPAction.getNodesWirelessNetworkConnections, {}),
      const MapEntry(JNAPAction.getNetworkConnections, {}),
      const MapEntry(JNAPAction.getRadioInfo, {}),
      if (isSupportGuestWiFi)
        const MapEntry(JNAPAction.getGuestRadioSettings, {}),
      const MapEntry(JNAPAction.getDevices, {}),
      const MapEntry(JNAPAction.getFirmwareUpdateSettings, {}),
      if ((mode ?? 'Unconfigured') == 'Master')
        const MapEntry(JNAPAction.getBackhaulInfo, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
      const MapEntry(JNAPAction.getEthernetPortConnections, {}),
      const MapEntry(JNAPAction.getSystemStats, {}),
      const MapEntry(JNAPAction.getPowerTableSettings, {}),
      const MapEntry(JNAPAction.getLocalTime, {}),
      const MapEntry(JNAPAction.getDeviceInfo, {}),
    ];
    if (serviceHelper.isSupportSetup()) {
      commands.add(
        const MapEntry(JNAPAction.getInternetConnectionStatus, {}),
      );
    }
    if (serviceHelper.isSupportHealthCheck()) {
      commands.add(const MapEntry(JNAPAction.getHealthCheckResults, {
        'includeModuleResults': true,
        "lastNumberOfResults": 5,
      }));
      commands
          .add(const MapEntry(JNAPAction.getSupportedHealthCheckModules, {}));
    }
    if (serviceHelper.isSupportNodeFirmwareUpdate()) {
      commands.add(
        const MapEntry(JNAPAction.getNodesFirmwareUpdateStatus, {}),
      );
    } else {
      commands.add(
        const MapEntry(JNAPAction.getFirmwareUpdateStatus, {}),
      );
    }
    if (serviceHelper.isSupportProduct()) {
      commands.add(const MapEntry(JNAPAction.getSoftSKUSettings, {}));
    }

    // For additional features
    if (serviceHelper.isSupportLedMode()) {
      commands.add(const MapEntry(JNAPAction.getLedNightModeSetting, {}));
    }
    commands.add(const MapEntry(JNAPAction.getMACFilterSettings, {}));

    return commands;
  }

  /// The router's device mode - 'Master', 'Slave', 'Unconfigured'.
  ///
  /// Never rejects. The read goes out with `fetchRemote: true`, so it never
  /// answers from cache, and a connection-level failure gets no retry from the
  /// HTTP client (only a TimeoutException does) - which made this the likeliest
  /// step of the start-up sequence to fail, and it used to take the whole of
  /// polling down with it. The mode decides one command, so the last known
  /// answer - or 'Unconfigured' when the router has never given one - is a far
  /// better outcome here than a rejected future.
  Future<String> checkSmartMode() async {
    final routerRepository = ref.read(routerRepositoryProvider);
    try {
      final result = await routerRepository.send(
        JNAPAction.getDeviceMode,
        fetchRemote: true,
      );
      _lastKnownMode = result.output['mode'] as String? ?? 'Unconfigured';
    } catch (e) {
      logger.e('Polling: could not read the device mode, '
          'falling back to ${_lastKnownMode ?? 'Unconfigured'}: $e');
    }
    return _lastKnownMode ?? 'Unconfigured';
  }
}
