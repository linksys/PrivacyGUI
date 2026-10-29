import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_notifier.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';
import 'package:privacy_gui/page/add_nodes/views/add_nodes_view.dart';
import 'package:privacy_gui/page/add_nodes/views/components/add_nodes_phase_content.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_add_nodes.dart';
import '../../../mocks/test_data/scenes/add_nodes_scene_data.dart';

/// Counts the actions the page asks of the flow.
class _RecordingAddNodesNotifier extends FixedAddNodesNotifier {
  int starts = 0;
  int cancels = 0;
  int rechecks = 0;

  _RecordingAddNodesNotifier(super.state);

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> cancel() async => cancels++;

  @override
  Future<void> recheck() async => rechecks++;
}

void main() {
  late _RecordingAddNodesNotifier notifier;

  /// Pumps the real page in [state], through the host the layout gate uses.
  Future<void> pump(WidgetTester tester, AddNodesState state) async {
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    notifier = _RecordingAddNodesNotifier(state);
    await tester.pumpWidget(pageSurfaceHost(
      view: const AddNodesView(),
      locale: const Locale('en'),
      overrides: [addNodesProvider.overrideWith(() => notifier)],
      // Where Done and Cancel lead when there is no page to pop back to.
      extraRoutes: [
        LinksysRoute(
          path: RoutePath.uspTopology,
          name: RouteNamed.uspTopology,
          builder: (context, state) =>
              const Scaffold(body: Text('topology page')),
        ),
      ],
    ));
    // Not pumpAndSettle: the waiting phases spin for ever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(AppButton, label));
    await tester.pump();
  }

  group('AddNodesView - phases', () {
    testWidgets('ready offers the guidance and Start', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesReadyState);

      expect(byId('add-nodes'), findsOneWidget);
      expect(byId('add-nodes-phase-ready'), findsOneWidget);
      expect(byId('add-nodes-start'), findsOneWidget);
      // AppStyledText renders spans, which only a RichText search sees.
      expect(find.textContaining('solid blue light', findRichText: true),
          findsOneWidget);

      await tapButton(tester, 'Start');
      expect(notifier.starts, 1);
      handle.dispose();
    });

    testWidgets('searching spins, and Cancel stops and leaves the page',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesSearchingState);

      expect(byId('add-nodes-phase-searching'), findsOneWidget);
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text('Searching for nodes...'), findsOneWidget);
      expect(find.byType(AppNodeListCard), findsNothing,
          reason: 'nothing found yet, so no list');
      expect(byId('add-nodes-start'), findsNothing);

      await tapButton(tester, 'Cancel');
      await tester.pump(const Duration(milliseconds: 300));
      expect(notifier.cancels, 1,
          reason: 'no node is joining, so there is nothing to ask about');
      expect(find.text('Stop adding nodes?'), findsNothing);
      expect(find.text('topology page'), findsOneWidget,
          reason: 'with nothing to pop back to, the topology is where it goes');
      handle.dispose();
    });

    testWidgets('onboarding lists each node found with its outcome',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesOnboardingState);

      expect(byId('add-nodes-phase-onboarding'), findsOneWidget);
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.byType(AppNodeListCard), findsNWidgets(2));
      expect(find.text('Joining…'), findsOneWidget,
          reason: 'the node being onboarded');
      expect(find.text('Not tried yet'), findsOneWidget,
          reason: 'the node queued behind it');
      expect(byId('add-nodes-cancel'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('joining lists each node and offers nothing to press',
        (tester) async {
      // The session is over by then: no Stop() to send, and no result yet.
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesJoiningState);

      expect(byId('add-nodes-phase-joining'), findsOneWidget);
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text('Bringing your new node online'), findsOneWidget);
      expect(find.text('Added'), findsOneWidget);
      expect(find.text('Joining…'), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
      handle.dispose();
    });

    testWidgets('busy says so and offers Check again, not Start',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesBusyState);

      expect(byId('add-nodes-phase-busy'), findsOneWidget);
      expect(find.text('A node is already being added'), findsOneWidget);
      expect(byId('add-nodes-start'), findsNothing);

      await tapButton(tester, 'Check again');
      expect(notifier.rechecks, 1);
      handle.dispose();
    });

    testWidgets('unavailable says so and offers Check again', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const AddNodesState(phase: AddNodesPhase.unavailable));

      expect(byId('add-nodes-phase-unavailable'), findsOneWidget);
      expect(
          find.text("Adding nodes isn't available right now"), findsOneWidget);
      expect(byId('add-nodes-recheck'), findsOneWidget);
      expect(byId('add-nodes-start'), findsNothing);
      handle.dispose();
    });

    testWidgets('a failed entry read shows the error and offers Check again',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
          tester,
          const AddNodesState(
              phase: AddNodesPhase.loadFailed, error: NetworkError()));

      expect(byId('add-nodes-phase-loadFailed'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
      expect(byId('add-nodes-recheck'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no nodes found lists what to check and offers Try again',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesNoNodesFoundState);

      expect(byId('add-nodes-phase-noNodesFound'), findsOneWidget);
      expect(find.text('No nodes found'), findsOneWidget);
      expect(find.text("Let's check a few things"), findsOneWidget);
      expect(find.byType(AppBulletList), findsOneWidget);

      await tapButton(tester, 'Try again');
      expect(notifier.starts, 1);
      handle.dispose();
    });

    testWidgets('joined lists the nodes and says where to put them',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesJoinedState);

      expect(byId('add-nodes-phase-joined'), findsOneWidget);
      expect(find.text('Node added'), findsOneWidget);
      expect(find.text('Added'), findsOneWidget,
          reason: 'in words, not only the check mark');
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Go ahead and move child nodes'), findsOneWidget);
      expect(find.text("Let's try again"), findsNothing);
      expect(byId('add-nodes-done'), findsOneWidget);
      expect(byId('add-nodes-start'), findsNothing);
      handle.dispose();
    });

    testWidgets(
        'partial lists every node found, the checklist and Try again, '
        'and not where to put them', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesPartialState);

      expect(byId('add-nodes-phase-partial'), findsOneWidget);
      expect(find.text('Some nodes were added'), findsOneWidget);
      expect(find.byType(AppNodeListCard), findsNWidgets(4));
      expect(find.text('Added'), findsOneWidget);
      expect(find.text("Couldn't add"), findsNWidgets(2),
          reason: 'the one out of WPS time and the one never reached over BLE');
      expect(find.text('Not tried yet'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text("Let's try again"), findsOneWidget);
      expect(find.text("Let's check a few things"), findsNothing,
          reason: "No nodes found's checklist assumes none was found");
      expect(find.text('Go ahead and move child nodes'), findsNothing);
      expect(byId('add-nodes-done'), findsOneWidget);

      await tapButton(tester, 'Try again');
      expect(notifier.starts, 1);
      handle.dispose();
    });

    testWidgets('failed lists the nodes found with their outcome',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, addNodesFailedWaitingState);

      expect(byId('add-nodes-phase-failed'), findsOneWidget);
      expect(find.text("Couldn't add a node"), findsOneWidget);
      expect(find.text("Couldn't add"), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.text("Let's try again"), findsOneWidget);
      expect(find.text("Let's check a few things"), findsNothing);
      expect(byId('add-nodes-start'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
        'failed with no node found checks the lights and range, '
        'not the nodes to move', (tester) async {
      // The limit ran out while scanning: nothing was found to move closer.
      final handle = tester.ensureSemantics();
      await pump(tester, const AddNodesState(phase: AddNodesPhase.failed));

      expect(find.text("Couldn't add a node"), findsOneWidget);
      expect(find.byType(AppNodeListCard), findsNothing);
      expect(find.text("Let's check a few things"), findsOneWidget);
      expect(find.text("Let's try again"), findsNothing);
      expect(byId('add-nodes-start'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a failed request shows its error, not the checklist',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
          tester,
          const AddNodesState(
              phase: AddNodesPhase.failed, error: TimeoutError()));

      expect(find.textContaining('timed out'), findsOneWidget);
      expect(find.text("Let's try again"), findsNothing);
      handle.dispose();
    });

    testWidgets('cancelled offers Try again', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const AddNodesState(phase: AddNodesPhase.cancelled));

      expect(byId('add-nodes-phase-cancelled'), findsOneWidget);
      expect(byId('add-nodes-start'), findsOneWidget);
      handle.dispose();
    });
  });

  // Cancel leaves the page, asking first when a node is already joining
  // (#1738). Pumped as the bare content with Done counted, so leaving is a
  // count rather than a route to find; the pages' own Done is #1734's and the
  // topology's existing navigateBack.
  group('AddNodesPhaseContent - cancel', () {
    late int cancels;
    late int leaves;

    Future<void> pumpContent(WidgetTester tester, AddNodesState state) async {
      tester.view.physicalSize = const Size(480, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      cancels = 0;
      leaves = 0;
      await tester.pumpWidget(pageSurfaceHost(
        view: Scaffold(
          body: AddNodesPhaseContent(
            state: state,
            onStart: () {},
            onCancel: () async => cancels++,
            onRecheck: () {},
            onDone: () => leaves++,
          ),
        ),
        locale: const Locale('en'),
      ));
      await tester.pump();
    }

    Future<void> tapCancel(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // One onboarded and one still onboarding: one node a stop would not undo.
    const oneJoining = AddNodesState(
      phase: AddNodesPhase.onboarding,
      nodes: [
        AddNodesNodeUIModel(
          bleMacAddress: 'AA:BB:CC:00:00:01',
          status: OnboardingNodeStatus.onboarded,
          modelNumber: 'M60',
          alMacAddress: 'aa:bb:cc:00:00:02',
        ),
        AddNodesNodeUIModel(
          bleMacAddress: 'AA:BB:CC:00:00:03',
          status: OnboardingNodeStatus.onboarding,
          modelNumber: 'M60',
        ),
      ],
    );

    testWidgets('with no node joining, stops and leaves at once',
        (tester) async {
      await pumpContent(tester, addNodesOnboardingState);

      await tapCancel(tester);

      expect(find.text('Stop adding nodes?'), findsNothing);
      expect(cancels, 1);
      expect(leaves, 1, reason: 'back to the step or topology that opened it');
    });

    testWidgets('with a node joining, asks first and says how many',
        (tester) async {
      await pumpContent(tester, oneJoining);

      await tapCancel(tester);

      expect(find.text('Stop adding nodes?'), findsOneWidget);
      expect(find.textContaining('1 node is already joining'), findsOneWidget);
      expect(cancels, 0, reason: 'nothing is stopped before the answer');
      expect(leaves, 0);
    });

    testWidgets('Keep adding closes the question and stops nothing',
        (tester) async {
      await pumpContent(tester, oneJoining);
      await tapCancel(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Keep adding'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Stop adding nodes?'), findsNothing);
      expect(cancels, 0);
      expect(leaves, 0);
      expect(find.widgetWithText(AppButton, 'Cancel'), findsOneWidget,
          reason: 'still on the session');
    });

    testWidgets('Stop stops the session, then leaves', (tester) async {
      await pumpContent(tester, oneJoining);
      await tapCancel(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Stop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cancels, 1);
      expect(leaves, 1);
    });
  });
}
