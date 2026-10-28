import 'package:flutter/material.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';
import 'package:privacy_gui/page/add_nodes/models/add_nodes_ui_models.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// What the add-nodes page shows for one [AddNodesState].
///
/// Stateless and provider-free: the page hands in the state and the actions,
/// so every phase can be pumped on its own.
///
/// Two layouts, by what the phase asks of the user. A phase the router is
/// working through (checking, starting, searching, onboarding, joining) is a
/// centred status — there is nothing to do but wait, and a cancel where there
/// is a session to stop. Every other phase is a column the user reads top to
/// bottom, with its actions inline at the end, the way the PnP wizard lays out
/// a step.
class AddNodesPhaseContent extends StatelessWidget {
  final AddNodesState state;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final VoidCallback onRecheck;
  final VoidCallback onDone;

  const AddNodesPhaseContent({
    super.key,
    required this.state,
    required this.onStart,
    required this.onCancel,
    required this.onRecheck,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // One anchor per page, keyed on the phase rather than on translated copy,
      // the shape the firmware pages use for their phase walk.
      identifier: 'add-nodes-phase-${state.phase.name}',
      child: switch (state.phase) {
        AddNodesPhase.checking =>
          _status(context, title: loc(context).addNodes),
        AddNodesPhase.starting || AddNodesPhase.searching => _status(
            context,
            title: loc(context).addNodesSearchingNodes,
            description: loc(context).addNodesSearchingNodesDesc,
            cancellable: true,
          ),
        AddNodesPhase.onboarding => _status(
            context,
            title: loc(context).addNodesOnboardingNodes,
            description: loc(context).addNodesOnboardingNodesDesc,
            cancellable: true,
          ),
        AddNodesPhase.joining =>
          _status(context, title: loc(context).addNodesJoining),
        AddNodesPhase.ready => _guidance(context),
        AddNodesPhase.loadFailed => _message(
            context,
            title: loc(context).addNodes,
            description: state.error == null
                ? loc(context).errorUnexpected
                : localizeServiceError(context, state.error!),
            actions: [
              _recheckButton(context, primary: true),
              _doneButton(context)
            ],
          ),
        AddNodesPhase.busy => _message(
            context,
            title: loc(context).addNodesBusy,
            description: loc(context).addNodesBusyDesc,
            actions: [
              _recheckButton(context, primary: true),
              _doneButton(context)
            ],
          ),
        AddNodesPhase.unavailable => _message(
            context,
            title: loc(context).addNodesUnavailable,
            description: loc(context).addNodesUnavailableDesc,
            actions: [
              _recheckButton(context, primary: true),
              _doneButton(context)
            ],
          ),
        AddNodesPhase.noNodesFound => _noNodesFound(context),
        AddNodesPhase.failed => _failed(context),
        AddNodesPhase.joined || AddNodesPhase.partial => _joined(context),
        AddNodesPhase.cancelled => _message(
            context,
            title: loc(context).addNodes,
            actions: [
              _startButton(context, label: loc(context).tryAgain),
              _doneButton(context)
            ],
          ),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Phases
  // ---------------------------------------------------------------------------

  /// Before a session: how to get the new node ready.
  Widget _guidance(BuildContext context) => _column(
        context,
        children: [
          AppText.headlineSmall(loc(context).addNodes),
          AppGap.lg(),
          AppStyledText(text: loc(context).addNodesDesc),
          AppGap.lg(),
          AppStyledText(text: loc(context).addNodesSolidBlueDesc),
        ],
        actions: [_startButton(context, label: loc(context).start)],
      );

  Widget _noNodesFound(BuildContext context) => _column(
        context,
        children: [
          AppText.headlineSmall(loc(context).addNodesNoNodesFoundTitle),
          AppGap.lg(),
          AppText.titleMedium(loc(context).modalTroubleshootNoNodesFound),
          AppGap.md(),
          AppBulletList(
            style: AppBulletStyle.number,
            children: [
              AppText.bodyMedium(
                  loc(context).modalTroubleshootNoNodesFoundDesc1),
              AppText.bodyMedium(
                  loc(context).modalTroubleshootNoNodesFoundDesc2),
            ],
          ),
        ],
        actions: [
          _startButton(context, label: loc(context).tryAgain),
          _doneButton(context),
        ],
      );

  /// No node joined. When the session itself reported a node onboarded, or one
  /// it gave up on, that node can still join after the flow stopped waiting —
  /// so the nodes are listed as not online yet rather than as lost.
  Widget _failed(BuildContext context) {
    final error = state.error;
    final waitedFor = state.nodes.where(_mightJoin).toList();
    return _column(
      context,
      children: [
        AppText.headlineSmall(loc(context).addNodesFailedTitle),
        AppGap.lg(),
        if (error != null)
          AppText.bodyMedium(localizeServiceError(context, error))
        else ...[
          AppText.titleMedium(loc(context).modalTroubleshootNoNodesFound),
          AppGap.md(),
          AppBulletList(
            style: AppBulletStyle.number,
            children: [
              AppText.bodyMedium(
                  loc(context).modalTroubleshootNoNodesFoundDesc1),
              AppText.bodyMedium(
                  loc(context).modalTroubleshootNoNodesFoundDesc2),
            ],
          ),
        ],
        if (waitedFor.isNotEmpty) ...[
          AppGap.xl(),
          _nodeList(context, waitedFor),
        ],
      ],
      actions: [
        _startButton(context, label: loc(context).tryAgain),
        _doneButton(context),
      ],
    );
  }

  /// At least one node joined. The ones still on their way are listed as not
  /// online yet, and the user is told where the new nodes should go.
  Widget _joined(BuildContext context) {
    final joinedCount = state.joinedNodeKeys.isEmpty
        // Taken at the session's word: it onboarded a node it had no AL MAC for.
        ? state.nodes.where((n) => n.isOnboarded).length
        : state.joinedNodeKeys.length;
    return _column(
      context,
      children: [
        AppText.headlineSmall(
            loc(context).addNodesAdded(joinedCount < 1 ? 1 : joinedCount)),
        AppGap.xl(),
        _nodeList(context, state.nodes.where(_mightJoin).toList()),
        AppGap.xl(),
        AppText.titleMedium(loc(context).modalMoveChildNodesTitle),
        AppGap.sm(),
        AppText.bodyMedium(loc(context).modalMoveChildNodesDesc),
      ],
      actions: [_doneButton(context, primary: true)],
    );
  }

  // ---------------------------------------------------------------------------
  // Node list
  // ---------------------------------------------------------------------------

  /// A node the session told to onboard, whether or not it finished.
  static bool _mightJoin(AddNodesNodeUIModel node) =>
      node.isOnboarded || node.mayStillJoin;

  Widget _nodeList(BuildContext context, List<AddNodesNodeUIModel> nodes) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final node in nodes) ...[
            _nodeCard(context, node),
            if (node != nodes.last) AppGap.sm(),
          ],
        ],
      );

  Widget _nodeCard(BuildContext context, AddNodesNodeUIModel node) {
    final alMac = node.alMacAddress;
    final joined =
        alMac != null && state.joinedNodeKeys.contains(meshNodeMacKey(alMac));
    final model = node.modelNumber;
    return AppNodeListCard(
      leading: DeviceImageHelper.getRouterImage(
          routerIconTestByModel(modelNumber: model ?? '')),
      title: model ?? node.bleMacAddress,
      description: joined ? null : loc(context).addNodesNotOnlineYet,
      trailing: joined
          ? AppIcon.font(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Layouts
  // ---------------------------------------------------------------------------

  /// A phase the router is working through: a spinner, what it is doing, and a
  /// cancel while a session is in progress. The notifier decides whether that
  /// cancel sends a `Stop()`.
  Widget _status(
    BuildContext context, {
    required String title,
    String? description,
    bool cancellable = false,
  }) =>
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoader(),
              AppGap.xl(),
              AppText.titleMedium(title, textAlign: TextAlign.center),
              if (description != null) ...[
                AppGap.sm(),
                AppText.bodyMedium(description, textAlign: TextAlign.center),
              ],
              if (cancellable && state.isRunning) ...[
                AppGap.xl(),
                AppButton.text(
                  label: loc(context).cancel,
                  identifier: 'add-nodes-cancel',
                  onTap: onCancel,
                ),
              ],
            ],
          ),
        ),
      );

  /// A phase with a title, an optional line and its actions.
  Widget _message(
    BuildContext context, {
    required String title,
    String? description,
    required List<Widget> actions,
  }) =>
      _column(
        context,
        children: [
          AppText.headlineSmall(title),
          if (description != null) ...[
            AppGap.lg(),
            AppText.bodyMedium(description),
          ],
        ],
        actions: actions,
      );

  /// Content top to bottom, then the actions inline and leading-aligned.
  Widget _column(
    BuildContext context, {
    required List<Widget> children,
    required List<Widget> actions,
  }) =>
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...children,
              AppGap.xxl(),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------

  Widget _startButton(BuildContext context, {required String label}) =>
      AppButton.primary(
        label: label,
        identifier: 'add-nodes-start',
        onTap: onStart,
      );

  Widget _recheckButton(BuildContext context, {bool primary = false}) => primary
      ? AppButton.primary(
          label: loc(context).addNodesCheckAgain,
          identifier: 'add-nodes-recheck',
          onTap: onRecheck,
        )
      : AppButton.text(
          label: loc(context).addNodesCheckAgain,
          identifier: 'add-nodes-recheck',
          onTap: onRecheck,
        );

  Widget _doneButton(BuildContext context, {bool primary = false}) => primary
      ? AppButton.primary(
          label: loc(context).done,
          identifier: 'add-nodes-done',
          onTap: onDone,
        )
      : AppButton.text(
          label: loc(context).done,
          identifier: 'add-nodes-done',
          onTap: onDone,
        );
}
