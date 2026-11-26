// Transmit Region reads the router's power table from the poll (#1922 P0):
// the input here is the poll's raw result, `Map<JNAPAction, JNAPResult>`, as
// polling hands it to its readers, not a pre-parsed snapshot. So these tests
// keep passing when #1922 decodes the poll in one place, and fail when what
// the page shows from it changes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_state.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';

/// A poll whose `GetPowerTableSettings` answered [output].
Map<JNAPAction, JNAPResult> _pollWith(Map<String, dynamic> output) => {
      JNAPAction.getPowerTableSettings:
          JNAPSuccess(result: 'OK', output: output),
    };

/// `GetPowerTableSettings` output, the supported regions in the router's own
/// order.
const _powerTable = <String, dynamic>{
  'isPowerTableSelectable': true,
  'supportedCountries': ['USA', 'TWN', 'EEE', 'CHN', 'AUS'],
  'country': 'TWN',
};

void main() {
  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;

  void open(Map<JNAPAction, JNAPResult> poll,
      {AccessPolicy policy = AccessPolicy.full}) {
    polling = RecordingPolling(poll);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
      accessPolicyProvider.overrideWithValue(policy),
    ]);
    addTearDown(container.dispose);
  }

  PowerTableState page() => container.read(powerTableProvider);
  PowerTableNotifier notifier() => container.read(powerTableProvider.notifier);

  setUp(() => router = RouterBoundary());

  group('from the poll', () {
    test('offers the regions the router supports, in a fixed order', () {
      open(_pollWith(_powerTable));

      expect(page().isPowerTableSelectable, isTrue);
      expect(page().supportedCountries, [
        PowerTableCountries.chn,
        PowerTableCountries.twn,
        PowerTableCountries.aus,
        PowerTableCountries.eee,
        PowerTableCountries.usa,
      ]);
    });

    test('shows the region the router is set to', () {
      open(_pollWith(_powerTable));

      expect(page().country, PowerTableCountries.twn);
    });

    test('hides the choice when the router says the region is fixed', () {
      open(_pollWith({..._powerTable, 'isPowerTableSelectable': false}));

      expect(page().isPowerTableSelectable, isFalse);
    });

    test(
        'hides the choice when the poll has no power table: before the first '
        'poll, or on a router without the PowerTable service', () {
      open(const {});

      expect(page().isPowerTableSelectable, isFalse);
      expect(page().supportedCountries, isEmpty);
      expect(page().country, isNull);
    });
  });

  group('save', () {
    test('writes the chosen region as the router names it', () async {
      open(_pollWith(_powerTable));

      await notifier().save(PowerTableCountries.eee);

      expect(router.payloadsOf(JNAPAction.setPowerTableSettings).single,
          {'country': 'EEE'});
    });

    test('pauses polling for the write, then resumes it and polls at once',
        () async {
      open(_pollWith(_powerTable));

      await notifier().save(PowerTableCountries.eee);

      expect(polling.stopped, 1);
      expect(polling.started, 1);
      expect(polling.forced, 1);
    });

    test('answers with the chosen region', () async {
      open(_pollWith(_powerTable));

      final saved = await notifier().save(PowerTableCountries.eee);

      expect(saved.country, PowerTableCountries.eee);
      expect(saved.supportedCountries, [
        PowerTableCountries.chn,
        PowerTableCountries.twn,
        PowerTableCountries.aus,
        PowerTableCountries.eee,
        PowerTableCountries.usa,
      ]);
    });

    test(
        'a refused write throws, and polling still resumes, with no forced '
        'poll', () async {
      open(_pollWith(_powerTable));
      router.refuses(JNAPAction.setPowerTableSettings,
          result: 'ErrorInvalidCountry');

      await expectLater(
          notifier().save(PowerTableCountries.eee),
          throwsA(isA<JNAPError>()
              .having((e) => e.result, 'result', 'ErrorInvalidCountry')));

      expect(polling.stopped, 1);
      expect(polling.started, 1);
      expect(polling.forced, 0);
    });

    test('a read-only login is refused before polling is touched', () async {
      open(_pollWith(_powerTable), policy: const AccessPolicy(canWrite: false));

      await expectLater(notifier().save(PowerTableCountries.eee),
          throwsA(isA<ReadOnlyAccessException>()));

      expect(router.sent, isEmpty);
      expect(polling.stopped, 0);
    });
  });

  group('region names', () {
    late BuildContext context;

    Future<void> openApp(WidgetTester tester) => tester.pumpWidget(MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (built) {
            context = built;
            return const SizedBox();
          }),
        ));

    testWidgets('names a region the way the picker lists it', (tester) async {
      await openApp(tester);

      expect(
          PowerTableCountries.chn.resolveDisplayText(context), 'Asia - China');
      expect(
          PowerTableCountries.usa.resolveDisplayText(context), 'United States');
      expect(PowerTableCountries.aus.resolveDisplayText(context),
          'Australia/New Zealand');
      expect(PowerTableCountries.nzl.resolveDisplayText(context),
          'Australia/New Zealand');
    });

    testWidgets(
        'gives every region a name of its own, except Australia and New '
        'Zealand, which share one', (tester) async {
      await openApp(tester);

      final names = [
        for (final region in PowerTableCountries.values)
          region.resolveDisplayText(context) as String,
      ];

      expect(names, everyElement(isNotEmpty));
      expect(names.toSet(), hasLength(PowerTableCountries.values.length - 1));
    });
  });
}
