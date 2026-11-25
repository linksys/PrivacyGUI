import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/management_settings.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_state.dart';

import '../../../../common/recording_polling.dart';
import '../../../../common/router_boundary.dart';

/// `GetManagementSettings2` output: the router lists RouterManagement2, as
/// every 1.x router does, so the app reads the support flag too.
const _management = <String, dynamic>{
  'canManageUsingHTTP': true,
  'canManageUsingHTTPS': false,
  'isManageWirelesslySupported': true,
  'canManageWirelessly': true,
  'canManageRemotely': false,
};

const _upnp = <String, dynamic>{
  'isUPnPEnabled': true,
  'canUsersConfigure': true,
  'canUsersDisableWANAccess': false,
};

const _alg = <String, dynamic>{'isSIPEnabled': true};

const _expressForwarding = <String, dynamic>{
  'isExpressForwardingSupported': true,
  'isExpressForwardingEnabled': false,
};

/// The last poll, as `GetEthernetPortConnections` reports a router's ports.
Map<JNAPAction, JNAPResult> _ports(List<String> lanPorts) => {
      JNAPAction.getEthernetPortConnections: JNAPSuccess(result: 'OK', output: {
        'wanPortConnection': '1Gbps',
        'lanPortConnections': lanPorts,
      }),
    };

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late AdministrationSettingsNotifier notifier;

  AdministrationSettingsState page() =>
      container.read(administrationSettingsProvider);

  /// A container for a router whose LAN ports are [lanPorts].
  void openPage({List<String> lanPorts = const ['None', '1Gbps', 'None']}) {
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => RecordingPolling(_ports(lanPorts))),
    ]);
    notifier = container.read(administrationSettingsProvider.notifier);
  }

  setUp(() {
    // A router that lists Router6, so the express forwarding actions are
    // mapped: #1866 decided to test Administration as it is, ungated.
    router = RouterBoundary()
      ..holds(JNAPAction.getManagementSettings, _management)
      ..holds(JNAPAction.getUPnPSettings, _upnp)
      ..holds(JNAPAction.getALGSettings, _alg)
      ..holds(JNAPAction.getExpressForwardingSettings, _expressForwarding);
    openPage();
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('reads the four settings in one transaction', () async {
      await notifier.fetch();

      expect(router.transactions.single.map((command) => command.key), [
        JNAPAction.getManagementSettings,
        JNAPAction.getUPnPSettings,
        JNAPAction.getALGSettings,
        JNAPAction.getExpressForwardingSettings,
      ]);
    });

    test('shows what the router holds', () async {
      final shown = await notifier.fetch();

      expect(shown, page());
      expect(
        page().managementSettings,
        const ManagementSettings(
          canManageUsingHTTP: true,
          canManageUsingHTTPS: false,
          isManageWirelesslySupported: true,
          canManageWirelessly: true,
          canManageRemotely: false,
        ),
      );
      expect(page().isUPnPEnabled, isTrue);
      expect(page().canUsersConfigure, isTrue);
      expect(page().canUsersDisableWANAccess, isFalse);
      expect(page().enabledALG, isTrue);
      expect(page().isExpressForwardingSupported, isTrue);
      expect(page().enabledExpressForwarfing, isFalse);
    });

    test('offers to block wireless management on a router with LAN ports',
        () async {
      await notifier.fetch();

      expect(page().canDisAllowLocalMangementWirelessly, isTrue);
    });

    test('does not offer it on a router with no LAN ports', () async {
      container.dispose();
      openPage(lanPorts: const []);

      await notifier.fetch();

      expect(page().canDisAllowLocalMangementWirelessly, isFalse);
    });

    test('reports a read the router refuses, and keeps the page', () async {
      router.refuses(JNAPAction.getALGSettings);
      final before = page();

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(page(), before);
    });
  });

  group('save', () {
    setUp(() async {
      await notifier.fetch();
      router
        ..sent.clear()
        ..transactions.clear();
    });

    test('writes the four settings in one transaction', () async {
      await notifier.save();

      expect(router.transactions.first.map((command) => command.key), [
        JNAPAction.setManagementSettings,
        JNAPAction.setUPnPSettings,
        JNAPAction.setALGSettings,
        JNAPAction.setExpressForwardingSettings,
      ]);
    });

    test('writes management access without the support flag', () async {
      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setManagementSettings).single, {
        'canManageUsingHTTP': true,
        'canManageUsingHTTPS': false,
        'canManageWirelessly': true,
        'canManageRemotely': false,
      });
    });

    test('writes the switches the user turned', () async {
      notifier
        ..setManagementSettings(false)
        ..setUPnPEnabled(false)
        ..setCanUsersConfigure(false)
        ..setCanUsersDisableWANAccess(true)
        ..setALGEnabled(false)
        ..setExpressForwarding(true);

      await notifier.save();

      expect(
        router
            .payloadsOf(JNAPAction.setManagementSettings)
            .single['canManageWirelessly'],
        isFalse,
      );
      expect(router.payloadsOf(JNAPAction.setUPnPSettings).single, {
        'isUPnPEnabled': false,
        'canUsersConfigure': false,
        'canUsersDisableWANAccess': true,
      });
      expect(router.payloadsOf(JNAPAction.setALGSettings).single,
          {'isSIPEnabled': false});
      expect(router.payloadsOf(JNAPAction.setExpressForwardingSettings).single,
          {'isExpressForwardingEnabled': true});
    });

    test('reads the settings back from the router after the write', () async {
      router.holds(JNAPAction.getALGSettings, {'isSIPEnabled': false});

      final saved = await notifier.save();

      expect(router.transactions, hasLength(2));
      expect(
          router.transactions.last.first.key, JNAPAction.getManagementSettings);
      expect(saved.enabledALG, isFalse);
      expect(page().enabledALG, isFalse);
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.refuses(JNAPAction.setALGSettings);
      notifier.setUPnPEnabled(false);

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.transactions, hasLength(1));
      expect(router.actions, isNot(contains(JNAPAction.getALGSettings)));
      // The page keeps the user's edit for another try.
      expect(page().isUPnPEnabled, isFalse);
    });

    test('reports a transaction that fails as a whole', () async {
      router.failsTransactions(const JNAPError(result: 'ErrorUnknown'));

      await expectLater(notifier.save(), throwsA(isA<JNAPError>()));

      expect(router.transactions, hasLength(1));
    });
  });
}
