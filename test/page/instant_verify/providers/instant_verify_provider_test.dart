// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/wan_external_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/wan_external_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/services/instant_verify_service.dart';

class MockInstantVerifyService extends Mock implements InstantVerifyService {}

void main() {
  late MockInstantVerifyService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockInstantVerifyService();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer({
    Map<JNAPAction, JNAPResult>? pollingData,
    WanExternalUIModel? wanExternal,
  }) {
    return ProviderContainer(
      overrides: [
        instantVerifyServiceProvider.overrideWithValue(mockService),
        pollingProvider.overrideWith(() {
          return MockPollingNotifier(pollingData ?? {});
        }),
        wanExternalProvider.overrideWith(() {
          return MockWanExternalNotifier(wanExternal);
        }),
      ],
    );
  }

  group('InstantVerifyNotifier', () {
    group('build()', () {
      test('returns initial state when no polling data', () {
        when(() => mockService.parseWanConnection(any())).thenReturn(null);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(RadioInfoUIModel.initial());
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());

        container = createContainer();

        final state = container.read(instantVerifyProvider);

        expect(state.wanConnection, isNull);
        expect(state.radioInfo, RadioInfoUIModel.initial());
        expect(state.guestRadioSettings, GuestRadioSettingsUIModel.initial());
        expect(state.wanExternal, isNull);
        expect(state.isRunning, isFalse);
      });

      test('uses service to parse polling data', () {
        const expectedWanConnection = WANConnectionUIModel(
          wanType: 'DHCP',
          ipAddress: '192.168.1.100',
          networkPrefixLength: 24,
          gateway: '192.168.1.1',
          mtu: 1500,
          dnsServer1: '8.8.8.8',
        );
        const expectedRadioInfo = RadioInfoUIModel(
          isBandSteeringSupported: true,
          radios: [],
        );

        when(() => mockService.parseWanConnection(any()))
            .thenReturn(expectedWanConnection);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(expectedRadioInfo);
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());

        container = createContainer();

        final state = container.read(instantVerifyProvider);

        expect(state.wanConnection, expectedWanConnection);
        expect(state.radioInfo, expectedRadioInfo);
        verify(() => mockService.parseWanConnection(any())).called(1);
        verify(() => mockService.parseRadioInfo(any())).called(1);
      });

      test('uses wanExternal directly from provider', () {
        const expectedWanExternal = WanExternalUIModel(
          publicWanIPv4: '203.0.113.1',
        );

        when(() => mockService.parseWanConnection(any())).thenReturn(null);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(RadioInfoUIModel.initial());
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());

        container = createContainer(wanExternal: expectedWanExternal);

        final state = container.read(instantVerifyProvider);

        expect(state.wanExternal, expectedWanExternal);
      });
    });

    group('ping()', () {
      test('sets isRunning to true and calls service.startPing', () async {
        when(() => mockService.parseWanConnection(any())).thenReturn(null);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(RadioInfoUIModel.initial());
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());
        when(() => mockService.startPing(
              host: any(named: 'host'),
              pingCount: any(named: 'pingCount'),
            )).thenAnswer((_) async {});

        container = createContainer();
        final notifier = container.read(instantVerifyProvider.notifier);

        await notifier.ping(host: '8.8.8.8', pingCount: 5);

        final state = container.read(instantVerifyProvider);
        expect(state.isRunning, isTrue);
        verify(() => mockService.startPing(host: '8.8.8.8', pingCount: 5))
            .called(1);
      });
    });

    group('stopPing()', () {
      test('sets isRunning to false and calls service.stopPing', () async {
        when(() => mockService.parseWanConnection(any())).thenReturn(null);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(RadioInfoUIModel.initial());
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());
        when(() => mockService.stopPing()).thenAnswer((_) async {});

        container = createContainer();
        final notifier = container.read(instantVerifyProvider.notifier);

        await notifier.stopPing();

        final state = container.read(instantVerifyProvider);
        expect(state.isRunning, isFalse);
        verify(() => mockService.stopPing()).called(1);
      });
    });

    group('getPingStatus()', () {
      test('returns stream from service', () {
        when(() => mockService.parseWanConnection(any())).thenReturn(null);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(RadioInfoUIModel.initial());
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());
        when(() => mockService.getPingStatus(
                onCompleted: any(named: 'onCompleted')))
            .thenAnswer((_) => Stream<PingStatusUIModel>.fromIterable([
                  PingStatusUIModel(isRunning: true, pingLog: 'ping 1'),
                  PingStatusUIModel(isRunning: false, pingLog: 'ping complete'),
                ]));

        container = createContainer();
        final notifier = container.read(instantVerifyProvider.notifier);

        final stream = notifier.getPingStatus();

        expect(stream, isA<Stream<PingStatusUIModel>>());
      });
    });

    group('traceroute()', () {
      test('sets isRunning to true and calls service.startTraceroute',
          () async {
        when(() => mockService.parseWanConnection(any())).thenReturn(null);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(RadioInfoUIModel.initial());
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());
        when(() => mockService.startTraceroute(host: '8.8.8.8'))
            .thenAnswer((_) async {});

        container = createContainer();
        final notifier = container.read(instantVerifyProvider.notifier);

        await notifier.traceroute(host: '8.8.8.8', pingCount: null);

        final state = container.read(instantVerifyProvider);
        expect(state.isRunning, isTrue);
        verify(() => mockService.startTraceroute(host: '8.8.8.8')).called(1);
      });
    });

    group('stopTraceroute()', () {
      test('sets isRunning to false and calls service.stopTraceroute',
          () async {
        when(() => mockService.parseWanConnection(any())).thenReturn(null);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(RadioInfoUIModel.initial());
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());
        when(() => mockService.stopTraceroute()).thenAnswer((_) async => null);

        container = createContainer();
        final notifier = container.read(instantVerifyProvider.notifier);

        await notifier.stopTraceroute();

        final state = container.read(instantVerifyProvider);
        expect(state.isRunning, isFalse);
        verify(() => mockService.stopTraceroute()).called(1);
      });
    });

    group('getTracerouteStatus()', () {
      test('returns stream from service', () {
        when(() => mockService.parseWanConnection(any())).thenReturn(null);
        when(() => mockService.parseRadioInfo(any()))
            .thenReturn(RadioInfoUIModel.initial());
        when(() => mockService.parseGuestRadioSettings(any()))
            .thenReturn(GuestRadioSettingsUIModel.initial());
        when(() => mockService.getTracerouteStatus(
                onCompleted: any(named: 'onCompleted')))
            .thenAnswer((_) => Stream<TracerouteStatusUIModel>.fromIterable([
                  TracerouteStatusUIModel(
                      isRunning: true, tracerouteLog: 'hop 1'),
                  TracerouteStatusUIModel(
                      isRunning: false, tracerouteLog: 'complete'),
                ]));

        container = createContainer();
        final notifier = container.read(instantVerifyProvider.notifier);

        final stream = notifier.getTracerouteStatus();

        expect(stream, isA<Stream<TracerouteStatusUIModel>>());
      });
    });
  });
}

// Mock classes for providers
class MockPollingNotifier extends AsyncNotifier<CoreTransactionData>
    implements PollingNotifier {
  final Map<JNAPAction, JNAPResult> _data;

  MockPollingNotifier(this._data);

  @override
  FutureOr<CoreTransactionData> build() {
    return CoreTransactionData(
      lastUpdate: DateTime.now().millisecondsSinceEpoch,
      isReady: true,
      data: _data,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockWanExternalNotifier extends Notifier<WANExternalState>
    implements WANExternalNotifier {
  final WanExternalUIModel? _wanExternal;

  MockWanExternalNotifier(this._wanExternal);

  @override
  WANExternalState build() {
    return WANExternalState(wanExternal: _wanExternal);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
