import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/traceroute_status.dart';
import 'package:privacy_gui/core/jnap/models/wan_external.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';

/// Riverpod provider for InstantVerifyService
final instantVerifyServiceProvider = Provider<InstantVerifyService>((ref) {
  return InstantVerifyService(
    ref.watch(routerRepositoryProvider),
  );
});

/// Stateless service for instant verify operations
///
/// Encapsulates JNAP communication, separating data access
/// from state management (InstantVerifyNotifier).
class InstantVerifyService {
  /// Constructor injection of dependencies
  InstantVerifyService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Parse polling data and extract WAN connection UI model
  ///
  /// Returns: WAN connection info extracted from polling data
  WANConnectionUIModel? parseWanConnection(
      Map<JNAPAction, JNAPResult> pollingData) {
    final wanStatusResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getWANStatus, pollingData);

    if (wanStatusResult == null) return null;

    final wanStatus = RouterWANStatus.fromMap(wanStatusResult.output);
    if (wanStatus.wanConnection == null) return null;

    return WANConnectionUIModel.fromJnap(wanStatus.wanConnection!);
  }

  /// Parse polling data and extract Radio info UI model
  ///
  /// Returns: Radio info extracted from polling data
  RadioInfoUIModel parseRadioInfo(Map<JNAPAction, JNAPResult> pollingData) {
    final radioInfoResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getRadioInfo, pollingData);

    if (radioInfoResult == null) {
      return const RadioInfoUIModel.initial();
    }

    final radioInfo = GetRadioInfo.fromMap(radioInfoResult.output);
    return RadioInfoUIModel.fromJnap(radioInfo);
  }

  /// Parse polling data and extract Guest Radio settings UI model
  ///
  /// Returns: Guest radio settings extracted from polling data
  GuestRadioSettingsUIModel parseGuestRadioSettings(
      Map<JNAPAction, JNAPResult> pollingData) {
    final guestRadioSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getGuestRadioSettings, pollingData);

    if (guestRadioSettingsResult == null) {
      return const GuestRadioSettingsUIModel.initial();
    }

    final guestRadioSettings =
        GuestRadioSettings.fromMap(guestRadioSettingsResult.output);
    return GuestRadioSettingsUIModel.fromJnap(guestRadioSettings);
  }

  /// Transform WanExternal JNAP model to UI model
  ///
  /// Returns: WAN external UI model, null if input is null
  WanExternalUIModel? transformWanExternal(WanExternal? wanExternal) {
    if (wanExternal == null) return null;
    return WanExternalUIModel.fromJnap(wanExternal);
  }

  /// Starts a Ping test to the specified host
  ///
  /// Parameters:
  ///   - host: Target hostname or IP address
  ///   - pingCount: Optional number of ping packets to send
  ///
  /// Returns: Future that completes when ping is started
  Future<void> startPing({required String host, int? pingCount}) {
    return _routerRepository.send(
      JNAPAction.startPing,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      auth: true,
      data: {'host': host, 'packetSizeBytes': 32, 'pingCount': pingCount}
        ..removeWhere((key, value) => value == null),
    );
  }

  /// Stops the currently running Ping test
  ///
  /// Returns: Future that completes when ping is stopped
  Future<void> stopPing() {
    return _routerRepository.send(
      JNAPAction.stopPing,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      auth: true,
    );
  }

  /// Gets the current Ping status as a stream of UI models
  ///
  /// Parameters:
  ///   - onCompleted: Callback when ping operation completes
  ///
  /// Returns: Stream of PingStatusUIModel updates
  Stream<PingStatusUIModel> getPingStatus({void Function()? onCompleted}) {
    return _routerRepository
        .scheduledCommand(
      action: JNAPAction.getPingStatus,
      retryDelayInMilliSec: 1000,
      maxRetry: 30,
      condition: (result) {
        if (result is JNAPSuccess) {
          final status = PingStatus.fromMap(result.output);
          return !status.isRunning;
        } else {
          return false;
        }
      },
      auth: true,
      onCompleted: (_) {
        onCompleted?.call();
      },
    )
        .map((event) {
      if (event is JNAPSuccess) {
        final status = PingStatus.fromMap(event.output);
        return PingStatusUIModel(
          isRunning: status.isRunning,
          pingLog: status.pingLog,
        );
      } else {
        throw event;
      }
    });
  }

  /// Starts a Traceroute test to the specified host
  ///
  /// Parameters:
  ///   - host: Target hostname or IP address
  ///
  /// Returns: Future that completes when traceroute is started
  Future<void> startTraceroute({required String host}) {
    return _routerRepository.send(
      JNAPAction.startTracroute,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      auth: true,
      data: {'host': host},
    );
  }

  /// Stops the currently running Traceroute test
  ///
  /// Returns: Future that completes when traceroute is stopped
  Future<void> stopTraceroute() {
    return _routerRepository.send(
      JNAPAction.stopTracroute,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      auth: true,
    );
  }

  /// Gets the current Traceroute status as a stream of UI models
  ///
  /// Parameters:
  ///   - onCompleted: Callback when traceroute operation completes
  ///
  /// Returns: Stream of TracerouteStatusUIModel updates
  Stream<TracerouteStatusUIModel> getTracerouteStatus(
      {void Function()? onCompleted}) {
    return _routerRepository
        .scheduledCommand(
      action: JNAPAction.getTracerouteStatus,
      retryDelayInMilliSec: 1000,
      maxRetry: 30,
      condition: (result) {
        if (result is JNAPSuccess) {
          final status = TracerouteStatus.fromMap(result.output);
          return !status.isRunning;
        } else {
          return false;
        }
      },
      auth: true,
      onCompleted: (_) {
        onCompleted?.call();
      },
    )
        .map((event) {
      if (event is JNAPSuccess) {
        final status = TracerouteStatus.fromMap(event.output);
        return TracerouteStatusUIModel(
          isRunning: status.isRunning,
          tracerouteLog: status.tracerouteLog,
        );
      } else {
        throw event;
      }
    });
  }
}
