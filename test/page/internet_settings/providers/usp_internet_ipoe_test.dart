import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/services/auto_ipoe_service.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';
import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockIPoE extends Mock implements AutoIPoEService {}

class MockWan extends Mock implements UspInternetSettingsService {}

class MockUsp extends Mock implements UspClient {}

AutoIPoESnapshot ipoeSnapshot(
    {bool managed = false,
    String? id,
    int? exitCode,
    bool reset = false,
    bool verified = false,
    bool busy = false}) {
  final base = AutoIPoETestData.snapshot(
      requestId: id,
      exitCode: exitCode,
      reset: reset,
      verified: verified,
      busy: busy);
  return AutoIPoESnapshot(
      capabilities: base.capabilities,
      settings: base.settings.copyWith(
          isEnabled: managed,
          selectedMode: managed ? AutoIPoEMode.auto : AutoIPoEMode.disabled),
      runtime: base.runtime.copyWith(
          isEnabled: managed,
          isCurrentWANType: managed,
          blockIPv6ManualConfiguration: managed,
          needsResetBeforeLeaving: managed),
      requestId: id,
      operationId: id,
      exitCode: exitCode,
      accepted: id != null);
}

class IPoEFixture {
  final ipoe = MockIPoE();
  final wan = MockWan();
  final calls = <String>[];
  late ProviderContainer container;
  late AutoIPoESnapshot latest;
  AutoIPoESubmission? submitted;
  var form = const UspInternetSettingsForm(
      connectionType: UspWanConnectionType.dhcp, mtu: 1500);
  bool disposed = false;
  IPoEFixture({bool managed = false}) {
    latest = ipoeSnapshot(managed: managed);
    when(() => ipoe.loadSubmission()).thenAnswer((_) async => null);
    when(() => ipoe.storeSubmission(any())).thenAnswer((_) async {});
    when(() => ipoe.fetch()).thenAnswer((_) async => latest);
    when(() => ipoe.submit(any(),
        settings: any(named: 'settings'),
        resetFirst: any(named: 'resetFirst'))).thenAnswer((call) async {
      submitted = call.positionalArguments.first as AutoIPoESubmission;
      calls.add(submitted!.reset ? 'reset' : 'apply');
      latest =
          ipoeSnapshot(managed: true, id: submitted!.requestId, busy: true);
      return AutoIPoEReceipt(
          accepted: true,
          requestId: submitted!.requestId,
          operationId: submitted!.requestId);
    });
    when(() => wan.fetchSettings()).thenAnswer((_) async =>
        InternetSettingsFetchResult(
            form: form, readOnlyInfo: const InternetSettingsReadOnlyInfo()));
    when(() => wan.saveAll(any(), any(),
            pppInstancePath: any(named: 'pppInstancePath'),
            vlanInstancePath: any(named: 'vlanInstancePath')))
        .thenAnswer((call) async {
      calls.add('ordinary');
      form = call.positionalArguments[1] as UspInternetSettingsForm;
    });
    container = ProviderContainer(overrides: [
      uspClientProvider.overrideWithValue(MockUsp()),
      uspInternetSettingsServiceProvider.overrideWithValue(wan),
      autoIPoEServiceProvider.overrideWithValue(ipoe),
    ]);
    container.listen(uspInternetSettingsProvider, (_, __) {});
    container.listen(autoIPoEPageProvider, (_, __) {});
  }
  UspInternetSettingsNotifier get notifier =>
      container.read(uspInternetSettingsProvider.notifier);
  Future<void> ready() async {
    await container.read(autoIPoEDataProvider.future);
    await container.read(autoIPoEPageProvider.notifier).fetch();
    await notifier.fetch();
    notifier.enterEditMode();
  }

  Future<void> publish(AutoIPoESnapshot snapshot) async {
    latest = snapshot;
    await container.read(autoIPoEDataProvider.notifier).refresh();
  }

  void dispose() {
    if (!disposed) {
      disposed = true;
      container.dispose();
    }
  }
}

Future<void> settleDispatch() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late IPoEFixture f;
  setUpAll(() {
    registerFallbackValue(
        const AutoIPoESubmission(AutoIPoETestData.id, reset: false));
    registerFallbackValue(const AutoIPoESettings.init());
    registerFallbackValue(const UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp));
  });
  tearDown(() => f.dispose());

  test(
      'managed IPoE is selected without changing the native WAN addressing type',
      () async {
    f = IPoEFixture(managed: true);
    await f.ready();
    expect(f.container.read(uspInternetSettingsProvider).connectionType,
        UspWanConnectionType.ipoe);
    expect(f.calls, isEmpty);
  });
  test('fresh partial capability read retains ownership and blocks IPoE Apply',
      () async {
    f = IPoEFixture(managed: true);
    final active = f.latest;
    f.latest = AutoIPoESnapshot(
        capabilitiesAvailable: false,
        settings: active.settings,
        runtime: active.runtime);
    await f.ready();
    expect(f.container.read(uspInternetSettingsProvider).connectionType,
        UspWanConnectionType.ipoe);
    expect(f.notifier.needsIPoEReset, true);
    expect(UspInternetSettingsNotifier.isManagedIPoE(f.latest), true);
    await expectLater(
        f.container.read(autoIPoEPageProvider.notifier).performSave(),
        throwsA(isA<ConnectivityError>()));
    expect(f.calls, isEmpty);
    await f.publish(active);
    expect(
        f.container
            .read(autoIPoEDataProvider)
            .requireValue
            .capabilitiesAvailable,
        true);
  });
  test('selecting IPoE only edits drafts and Cancel reverts both', () async {
    f = IPoEFixture();
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.ipoe);
    expect(f.container.read(autoIPoEPageProvider).current.isEnabled, isTrue);
    expect(f.container.read(autoIPoEPageProvider).current.selectedMode,
        AutoIPoEMode.auto);
    expect(f.notifier.isDirty(), isTrue);
    expect(f.calls, isEmpty);
    f.notifier.exitEditMode();
    expect(f.container.read(uspInternetSettingsProvider).connectionType,
        UspWanConnectionType.dhcp);
    expect(f.container.read(autoIPoEPageProvider).current.isEnabled, isFalse);
    expect(f.notifier.isDirty(), isFalse);
    expect(f.calls, isEmpty);
  });
  test('IPoE-only draft participates in existing route dirty checking',
      () async {
    f = IPoEFixture(managed: true);
    await f.ready();
    f.container.read(autoIPoEPageProvider.notifier).updateSettings(f.container
        .read(autoIPoEPageProvider)
        .current
        .copyWith(selectedMode: AutoIPoEMode.biglobeStaticIp));
    expect(f.container.read(uspInternetSettingsProvider).isDirty, isFalse);
    expect(f.container.read(uspInternetSettingsProvider.notifier).isDirty(),
        isTrue);
    f.container.read(uspInternetSettingsProvider.notifier).revert();
    expect(f.notifier.isDirty(), isFalse);
  });
  test('ordinary save stays ordinary and clears only an unapplied IPoE draft',
      () async {
    f = IPoEFixture();
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.ipoe);
    f.notifier.updateConnectionType(UspWanConnectionType.dhcp);
    await f.notifier.save();
    expect(f.calls, ['ordinary']);
    expect(f.notifier.isDirty(), isFalse);
    expect(f.container.read(autoIPoEPageProvider).isDirty, isFalse);
  });
  test('failed ordinary save preserves its unused IPoE draft', () async {
    f = IPoEFixture();
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.ipoe);
    f.notifier.updateConnectionType(UspWanConnectionType.dhcp);
    when(() => f.wan.saveAll(any(), any(),
            pppInstancePath: any(named: 'pppInstancePath'),
            vlanInstancePath: any(named: 'vlanInstancePath')))
        .thenThrow(const ConnectivityError());
    await expectLater(f.notifier.save(), throwsA(isA<ConnectivityError>()));
    expect(f.container.read(autoIPoEPageProvider).isDirty, isTrue);
    expect(f.calls, isEmpty);
  });
  test('IPoE Save dispatches once and stays dirty until verified completion',
      () async {
    f = IPoEFixture();
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.ipoe);
    final saving = f.notifier.save();
    await settleDispatch();
    expect(f.calls, ['apply']);
    expect(f.container.read(autoIPoEPageProvider).isDirty, isTrue);
    await expectLater(f.notifier.save(), throwsA(isA<InvalidInputError>()));
    await f.publish(ipoeSnapshot(
        managed: true,
        id: f.submitted!.requestId,
        exitCode: 0,
        verified: true));
    await saving;
    expect(f.calls, ['apply']);
    expect(f.notifier.isDirty(), isFalse);
    expect(f.container.read(autoIPoEPageProvider).isDirty, isFalse);
  });
  test('rejected IPoE Save preserves form and never calls ordinary WAN service',
      () async {
    f = IPoEFixture();
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.ipoe);
    when(() => f.ipoe
        .submit(any(),
            settings: any(named: 'settings'),
            resetFirst: any(named: 'resetFirst'))).thenAnswer((_) async =>
        const AutoIPoEReceipt(accepted: false, error: 'ErrorInvalidSettings'));
    await expectLater(f.notifier.save(), throwsA(isA<InvalidInputError>()));
    expect(f.container.read(autoIPoEPageProvider).isDirty, isTrue);
    expect(f.notifier.isDirty(), isTrue);
    expect(f.calls, isEmpty);
  });
  test('zero exit without verified connectivity does not save IPoE draft',
      () async {
    f = IPoEFixture();
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.ipoe);
    final saving =
        expectLater(f.notifier.save(), throwsA(isA<InvalidInputError>()));
    await settleDispatch();
    await f.publish(
        ipoeSnapshot(managed: true, id: f.submitted!.requestId, exitCode: 0));
    await saving;
    expect(f.container.read(autoIPoEPageProvider).isDirty, isTrue);
    expect(f.calls, ['apply']);
  });
  test('switch-away needs explicit existing reset confirmation', () async {
    f = IPoEFixture(managed: true);
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.dhcp);
    await expectLater(f.notifier.save(), throwsA(isA<InvalidInputError>()));
    expect(f.calls, isEmpty);
  });
  test('switch-away waits for matching verified reset then saves ordinary once',
      () async {
    f = IPoEFixture(managed: true);
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.dhcp);
    final saving = f.notifier.save(resetConfirmed: true);
    await settleDispatch();
    expect(f.calls, ['reset']);
    await f.publish(ipoeSnapshot(
        managed: false, id: 'another-job', exitCode: 0, reset: true));
    expect(f.calls, ['reset']);
    await f.publish(ipoeSnapshot(
        managed: false, id: f.submitted!.requestId, exitCode: 0, reset: true));
    await saving;
    await f.container.read(autoIPoEDataProvider.notifier).refresh();
    expect(f.calls, ['reset', 'ordinary']);
    expect(f.notifier.isDirty(), isFalse);
  });
  test('reset failure blocks ordinary save and retains requested WAN draft',
      () async {
    f = IPoEFixture(managed: true);
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.pppoe);
    final saving = expectLater(f.notifier.save(resetConfirmed: true),
        throwsA(isA<InvalidInputError>()));
    await settleDispatch();
    await f.publish(ipoeSnapshot(
        managed: true, id: f.submitted!.requestId, exitCode: 1, reset: true));
    await saving;
    expect(f.calls, ['reset']);
    expect(f.container.read(uspInternetSettingsProvider).connectionType,
        UspWanConnectionType.pppoe);
    expect(f.notifier.isDirty(), isTrue);
  });
  test(
      'reset completion while managed state remains cannot enable ordinary save',
      () async {
    f = IPoEFixture(managed: true);
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.dhcp);
    final saving = expectLater(f.notifier.save(resetConfirmed: true),
        throwsA(isA<InvalidInputError>()));
    await settleDispatch();
    await f.publish(ipoeSnapshot(
        managed: true, id: f.submitted!.requestId, exitCode: 0, reset: true));
    await saving;
    expect(f.calls, ['reset']);
  });
  test(
      'disconnect aborts ordinary continuation; reconnect only polls same UUID',
      () async {
    f = IPoEFixture(managed: true);
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.dhcp);
    final saving = expectLater(f.notifier.save(resetConfirmed: true),
        throwsA(isA<ConnectivityError>()));
    await settleDispatch();
    final id = f.submitted!.requestId;
    when(() => f.ipoe.fetch()).thenThrow(const ConnectivityError());
    await f.container.read(autoIPoEDataProvider.notifier).refresh();
    await saving;
    when(() => f.ipoe.fetch()).thenAnswer((_) async => f.latest);
    await f.publish(ipoeSnapshot(id: id, exitCode: 0, reset: true));
    expect(f.calls, ['reset']);
    expect(f.container.read(autoIPoESubmissionProvider)!.requestId, id);
  });
  test('navigation disposal cannot continue a pending reset into ordinary save',
      () async {
    f = IPoEFixture(managed: true);
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.dhcp);
    final saving = expectLater(f.notifier.save(resetConfirmed: true),
        throwsA(isA<ConnectivityError>()));
    await settleDispatch();
    f.dispose();
    await saving;
    expect(f.calls, ['reset']);
  });
  test('optional backend failure leaves ordinary settings load usable',
      () async {
    f = IPoEFixture();
    await f.ready();
    when(() => f.ipoe.fetch()).thenThrow(const ConnectivityError());
    await f.container.read(autoIPoEDataProvider.notifier).refresh();
    await f.notifier.fetch();
    expect(f.container.read(uspInternetSettingsProvider).status.error, isNull);
    expect(f.container.read(uspInternetSettingsProvider).connectionType,
        UspWanConnectionType.dhcp);
  });
  test('late managed status never overwrites an explicit connection type draft',
      () async {
    f = IPoEFixture();
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.pppoe);
    await f.publish(ipoeSnapshot(managed: true));
    expect(f.container.read(uspInternetSettingsProvider).connectionType,
        UspWanConnectionType.pppoe);
    expect(
        f.container.read(uspInternetSettingsProvider).original.connectionType,
        UspWanConnectionType.ipoe);
  });
  test('later managed IPoE status updates display after ordinary editing ends',
      () async {
    f = IPoEFixture();
    await f.ready();
    f.notifier.updateConnectionType(UspWanConnectionType.dhcp);
    await f.notifier.save();
    expect(f.container.read(uspInternetSettingsProvider).isEditing, isFalse);
    await f.publish(ipoeSnapshot(managed: true));
    expect(f.container.read(uspInternetSettingsProvider).connectionType,
        UspWanConnectionType.ipoe);
    expect(f.container.read(uspInternetSettingsProvider).isDirty, isFalse);
  });
}
