import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/wan_external_provider.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';
import 'package:privacy_gui/page/instant_verify/services/instant_verify_service.dart';

final instantVerifyProvider =
    NotifierProvider<InstantVerifyNotifier, InstantVerifyState>(
        () => InstantVerifyNotifier());

/// Notifier for InstantVerify feature
///
/// Manages UI state and delegates business logic to InstantVerifyService.
/// Does not directly interact with JNAP - all data access goes through Service.
class InstantVerifyNotifier extends Notifier<InstantVerifyState> {
  @override
  InstantVerifyState build() {
    final service = ref.read(instantVerifyServiceProvider);
    final pollingData = ref.watch(pollingProvider).value?.data ?? {};
    final wanExternalData =
        ref.watch(wanExternalProvider.select((state) => state.wanExternal));

    // Use service to parse polling data and transform to UI models
    final wanConnection = service.parseWanConnection(pollingData);
    final radioInfo = service.parseRadioInfo(pollingData);
    final guestRadioSettings = service.parseGuestRadioSettings(pollingData);
    final wanExternal = service.transformWanExternal(wanExternalData);

    return InstantVerifyState(
      wanConnection: wanConnection,
      radioInfo: radioInfo,
      guestRadioSettings: guestRadioSettings,
      wanExternal: wanExternal,
    );
  }

  /// Starts a Ping test to the specified host
  ///
  /// Parameters:
  ///   - host: Target hostname or IP address
  ///   - pingCount: Optional number of ping packets to send
  Future<void> ping({required String host, required int? pingCount}) async {
    state = state.copyWith(isRunning: true);
    final service = ref.read(instantVerifyServiceProvider);
    try {
      await service.startPing(host: host, pingCount: pingCount);
    } catch (_) {
      state = state.copyWith(isRunning: false);
      rethrow;
    }
  }

  /// Stops the currently running Ping test
  Future<void> stopPing() {
    state = state.copyWith(isRunning: false);
    final service = ref.read(instantVerifyServiceProvider);
    return service.stopPing();
  }

  /// Gets the current Ping status as a stream
  ///
  /// Returns: Stream of PingStatusUIModel updates
  Stream<PingStatusUIModel> getPingStatus() {
    final service = ref.read(instantVerifyServiceProvider);
    return service.getPingStatus(
      onCompleted: () {
        state = state.copyWith(isRunning: false);
      },
    );
  }

  /// Starts a Traceroute test to the specified host
  ///
  /// Parameters:
  ///   - host: Target hostname or IP address
  ///   - pingCount: Unused, kept for API compatibility
  Future<void> traceroute(
      {required String host, required int? pingCount}) async {
    state = state.copyWith(isRunning: true);
    final service = ref.read(instantVerifyServiceProvider);
    try {
      await service.startTraceroute(host: host);
    } catch (_) {
      state = state.copyWith(isRunning: false);
      rethrow;
    }
  }

  /// Stops the currently running Traceroute test
  Future<void> stopTraceroute() {
    state = state.copyWith(isRunning: false);
    final service = ref.read(instantVerifyServiceProvider);
    return service.stopTraceroute();
  }

  /// Gets the current Traceroute status as a stream
  ///
  /// Returns: Stream of TracerouteStatusUIModel updates
  Stream<TracerouteStatusUIModel> getTracerouteStatus() {
    final service = ref.read(instantVerifyServiceProvider);
    return service.getTracerouteStatus(
      onCompleted: () {
        state = state.copyWith(isRunning: false);
      },
    );
  }
}
