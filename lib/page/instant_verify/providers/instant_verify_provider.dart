import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/traceroute_status.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/wan_external_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_state.dart';

final instantVerifyProvider =
    NotifierProvider<InstantVerifyNotifier, InstantVerifyState>(
        () => InstantVerifyNotifier());

class InstantVerifyNotifier extends Notifier<InstantVerifyState> {
  @override
  InstantVerifyState build() {
    final pollingData = ref.watch(pollingProvider).value?.data ?? {};
    final wanStatusResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getWANStatus, pollingData);
    final wanStatus = wanStatusResult == null
        ? null
        : RouterWANStatus.fromMap(wanStatusResult.output);
    final radioInfoResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getRadioInfo, pollingData);
    final radioInfo = radioInfoResult == null
        ? null
        : GetRadioInfo.fromMap(radioInfoResult.output);
    final guestRadioSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getGuestRadioSettings, pollingData);
    final guestRadioSettings = guestRadioSettingsResult == null
        ? null
        : GuestRadioSettings.fromMap(guestRadioSettingsResult.output);

    final wanExternal =
        ref.watch(wanExternalProvider.select((state) => state.wanExternal));
    final state = InstantVerifyState(
      wanConnection: wanStatus?.wanConnection,
      radioInfo: radioInfo ??
          const GetRadioInfo(isBandSteeringSupported: false, radios: []),
      guestRadioSettings: guestRadioSettings ??
          const GuestRadioSettings(
            isGuestNetworkACaptivePortal: false,
            isGuestNetworkEnabled: false,
            radios: [],
          ),
      wanExternal: wanExternal,
    );
    return state;
  }

  Future ping({required String host, required int? pingCount}) {
    state = state.copyWith(isRunning: true);
    return ref.read(routerRepositoryProvider).send(JNAPAction.startPing,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        auth: true,
        data: {'host': host, 'packetSizeBytes': 32, 'pingCount': pingCount}
          ..removeWhere((key, value) => value == null));
  }

  Future stopPing() {
    state = state.copyWith(isRunning: false);
    return ref.read(routerRepositoryProvider).send(
          JNAPAction.stopPing,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          auth: true,
        );
  }

  Stream<PingStatus> getPingStatus() {
    return ref
        .read(routerRepositoryProvider)
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
          onCompleted: () {
            state = state.copyWith(isRunning: false);
          },
        )
        .map((event) {
      if (event is JNAPSuccess) {
        return PingStatus.fromMap(event.output);
      } else {
        throw event;
      }
    });
  }

  Future traceroute({required String host, required int? pingCount}) {
    state = state.copyWith(isRunning: true);
    return ref.read(routerRepositoryProvider).send(JNAPAction.startTracroute,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
        auth: true,
        data: {'host': host}..removeWhere((key, value) => value == null));
  }

  Future stopTraceroute() {
    state = state.copyWith(isRunning: false);
    return ref.read(routerRepositoryProvider).send(
          JNAPAction.stopTracroute,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
          auth: true,
        );
  }

  Stream<TracerouteStatus> getTracerouteStatus() {
    return ref
        .read(routerRepositoryProvider)
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
          onCompleted: () {
            state = state.copyWith(isRunning: false);
          },
        )
        .map((event) {
      if (event is JNAPSuccess) {
        return TracerouteStatus.fromMap(event.output);
      } else {
        throw event;
      }
    });
  }
}
