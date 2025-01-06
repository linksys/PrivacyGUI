import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/nodes/views/add_nodes_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../common/utils.dart';
import '../../../../test_data/device_test_data.dart';
import '../../../../mocks/add_nodes_notifier_mocks.dart';

void main() async {
  late MockAddNodesNotifier mockAddNodesNotifier;

  setUp(() {
    mockAddNodesNotifier = MockAddNodesNotifier();
    when(mockAddNodesNotifier.build()).thenReturn(const AddNodesState());
  });

  testLocalizations('Instant-Piar - add nodes view', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [
          addNodesProvider.overrideWith(() => mockAddNodesNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant-Piar - lights has different color modal',
      (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [
          addNodesProvider.overrideWith(() => mockAddNodesNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final btnFinder = find.byType(AppTextButton);
    await tester.tap(btnFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant-Piar - searching nodes', (tester, locale) async {
    final simple = SearchingMockAddNodesNotifier();
    await tester.pumpWidget(
      testableSingleRoute(
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [
          addNodesProvider.overrideWith(() => simple),
        ],
      ),
    );

    await tester.pumpAndSettle();
    final btnFinder = find.byType(AppFilledButton);
    await tester.tap(btnFinder);
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Instant-Piar - onboarding nodes', (tester, locale) async {
    final simple = OnboardingMockAddNodesNotifier();
    await tester.pumpWidget(
      testableSingleRoute(
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [
          addNodesProvider.overrideWith(() => simple),
        ],
      ),
    );

    await tester.pumpAndSettle();
    final btnFinder = find.byType(AppFilledButton);
    await tester.tap(btnFinder);
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Instant-Piar - no nodes found results',
      (tester, locale) async {
    when(mockAddNodesNotifier.build()).thenReturn(
        const AddNodesState(onboardingProceed: true, addedNodes: []));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [
          addNodesProvider.overrideWith(() => mockAddNodesNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant-Piar - troubleshoot modal',
      (tester, locale) async {
    when(mockAddNodesNotifier.build()).thenReturn(
        const AddNodesState(onboardingProceed: true, addedNodes: []));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [
          addNodesProvider.overrideWith(() => mockAddNodesNotifier),
        ],
      ),
    );

    await tester.pumpAndSettle();
    final styledTextFinder = find.byKey(ValueKey('troubleshoot')).first;
    // await tester.tap(styledTextFinder);
    fireOnTapByIndex(styledTextFinder, 0);
    await tester.pumpAndSettle();
  });

  testLocalizations(
      'Instant-Piar - troubleshoot light is a different color modal',
      (tester, locale) async {
    when(mockAddNodesNotifier.build()).thenReturn(
        const AddNodesState(onboardingProceed: true, addedNodes: []));

    await tester.pumpWidget(
      testableSingleRoute(
        child: const AddNodesView(),
        config:
            LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
        locale: locale,
        overrides: [
          addNodesProvider.overrideWith(() => mockAddNodesNotifier),
        ],
      ),
    );

    await tester.pumpAndSettle();
    final styledTextFinder = find.byKey(ValueKey('troubleshoot')).first;
    // await tester.tap(styledTextFinder);
    fireOnTapByIndex(styledTextFinder, 0);
    await tester.pumpAndSettle();
    final textBtnFinder = find
        .descendant(
            of: find.byType(Dialog), matching: find.byType(AppTextButton))
        .at(0);
    await tester.tap(textBtnFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant-Piar - results', (tester, locale) async {
    when(mockAddNodesNotifier.build()).thenReturn(AddNodesState(
      onboardingProceed: true,
      childNodes: [
        LinksysDevice.fromJson(singleDeviceData),
        LinksysDevice.fromMap(slaveCherry7TestData1),
        LinksysDevice.fromMap(slaveCherry7TestData2),
        LinksysDevice.fromMap(slaveCherry7TestData3),
        LinksysDevice.fromMap(slaveCherry7TestData4),
      ],
      addedNodes: [
        LinksysDevice.fromJson(singleDeviceData),
        LinksysDevice.fromMap(slaveCherry7TestData1),
        LinksysDevice.fromMap(slaveCherry7TestData2),
        LinksysDevice.fromMap(slaveCherry7TestData3),
        LinksysDevice.fromMap(slaveCherry7TestData4),
      ],
    ));

    // Pre-cached images to make image display proporly
    await tester.runAsync(() async {
      await tester.pumpWidget(
        testableSingleRoute(
          child: const AddNodesView(),
          config:
              LinksysRouteConfig(column: ColumnGrid(column: 6, centered: true)),
          locale: locale,
          overrides: [
            addNodesProvider.overrideWith(() => mockAddNodesNotifier),
          ],
        ),
      );
      final context = tester.element(find.byType(AddNodesView));
      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await tester.pumpAndSettle();
    });
  });
}

class SearchingMockAddNodesNotifier extends AddNodesNotifier with Mock {
  @override
  AddNodesState get state => const AddNodesState();

  @override
  set state(AddNodesState newState) {
    super.state = newState;
  }

  @override
  Future startAutoOnboarding() async {
    state = state.copyWith(isLoading: true, loadingMessage: 'searching');
    await Future.delayed(const Duration(seconds: 3));
    state = state.copyWith(isLoading: false, loadingMessage: null);
  }

  @override
  Future<bool> getAutoOnboardingSettings() async {
    return true;
  }
}

class OnboardingMockAddNodesNotifier extends AddNodesNotifier with Mock {
  @override
  AddNodesState get state => const AddNodesState();

  @override
  set state(AddNodesState newState) {
    super.state = newState;
  }

  @override
  Future startAutoOnboarding() async {
    state = state.copyWith(isLoading: true, loadingMessage: 'onboarding');
    await Future.delayed(const Duration(seconds: 3));
    state = state.copyWith(isLoading: false, loadingMessage: null);
  }

  @override
  Future<bool> getAutoOnboardingSettings() async {
    return true;
  }
}
