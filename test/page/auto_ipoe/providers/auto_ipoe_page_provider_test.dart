import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/services/auto_ipoe_service.dart';
import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockPageService extends Mock implements AutoIPoEService {}

class DraftData extends AutoIPoEDataNotifier {
  AutoIPoESettings? submitted;
  @override
  Future<AutoIPoESnapshot> build() async => AutoIPoETestData.snapshot();
  @override
  Future<void> apply(AutoIPoESettings settings,
      {bool resetFirst = false}) async {
    submitted = settings;
    state = AsyncData(AutoIPoETestData.snapshot(exitCode: 1));
  }
}

void main() {
  test('PnP failure preserves entered provider secrets and draft', () async {
    final data = DraftData();
    final container = ProviderContainer(
        overrides: [autoIPoEDataProvider.overrideWith(() => data)]);
    final sub = container.listen(autoIPoEPageProvider, (_, __) {});
    addTearDown(() {
      sub.close();
      container.dispose();
    });
    final page = container.read(autoIPoEPageProvider.notifier);
    await container.read(autoIPoEDataProvider.future);
    await page.fetch();
    final draft = AutoIPoETestData.settings.copyWith(
        selectedMode: AutoIPoEMode.biglobeStaticIp,
        biglobeStaticIpSettings: const BiglobeStaticIPSettings(
            userId: AutoIPoESecret(value: 'testuser'),
            userPassword: AutoIPoESecret(value: 'testsecret')));
    page.updateSettings(draft);
    await page.saveForPnp();
    expect(container.read(autoIPoEPageProvider).current, draft);
    expect(data.submitted, draft);
  });

  test('status refresh preserves edits while discard restores source settings',
      () async {
    final service = MockPageService();
    when(() => service.loadSubmission()).thenAnswer((_) async => null);
    when(() => service.fetch())
        .thenAnswer((_) async => AutoIPoETestData.snapshot());
    final container = ProviderContainer(
        overrides: [autoIPoEServiceProvider.overrideWithValue(service)]);
    final sub = container.listen(autoIPoEPageProvider, (_, next) {});
    addTearDown(() {
      sub.close();
      container.dispose();
    });
    final notifier = container.read(autoIPoEPageProvider.notifier);
    await container.read(autoIPoEDataProvider.future);
    await notifier.fetch();
    notifier.updateSettings(AutoIPoETestData.settings
        .copyWith(selectedMode: AutoIPoEMode.biglobeStaticIp));
    await container.read(autoIPoEDataProvider.notifier).refresh();
    expect(container.read(autoIPoEPageProvider).current.selectedMode,
        AutoIPoEMode.biglobeStaticIp);
    expect(container.read(autoIPoEPageProvider).isDirty, true);
    notifier.revert();
    expect(container.read(autoIPoEPageProvider).current.selectedMode,
        AutoIPoEMode.auto);
  });
}
