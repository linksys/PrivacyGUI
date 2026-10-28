import 'package:flutter/material.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
///
/// Both list every node the session found, each with its outcome (#1738), so
/// the result screen says nothing the waiting screens had not already shown.
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
        // Nothing to press until every node has an outcome: the session is
        // over, so there is no Stop() behind a cancel, and leaving is the
        // back arrow's job.
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
        AddNodesPhase.partial => _partial(context),
        AddNodesPhase.joined => _joined(context),
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

  /// No node joined. A failed request says why; otherwise each node says what
  /// became of it, and the checklist is for the ones the router found but could
  /// not add — not "No nodes found"'s, which assumes it found none.
  Widget _failed(BuildContext context) {
    final error = state.error;
    return _column(
      context,
      children: [
        AppText.headlineSmall(loc(context).addNodesFailedTitle),
        if (error != null) ...[
          AppGap.lg(),
          AppText.bodyMedium(localizeServiceError(context, error)),
        ],
        if (state.nodes.isNotEmpty) ...[
          AppGap.xl(),
          _nodeList(context),
        ],
        if (error == null) ...[
          AppGap.xl(),
          _failedTroubleshooting(context),
        ],
      ],
      actions: [
        _startButton(context, label: loc(context).tryAgain),
        _doneButton(context),
      ],
    );
  }

  /// Some nodes joined and some did not (#1738). Try again is for the rest, so
  /// the checklist is the failure's; where to put the new nodes waits until
  /// every node is in.
  Widget _partial(BuildContext context) => _column(
        context,
        children: [
          AppText.headlineSmall(loc(context).addNodesPartialTitle),
          AppGap.xl(),
          _nodeList(context),
          AppGap.xl(),
          _failedTroubleshooting(context),
        ],
        actions: [
          _startButton(context, label: loc(context).tryAgain),
          _doneButton(context),
        ],
      );

  /// Every node joined: the user is told where the new nodes should go.
  Widget _joined(BuildContext context) {
    final added = state.nodes
        .where((n) => state.outcomeFor(n) == AddNodesNodeOutcome.added)
        .length;
    return _column(
      context,
      children: [
        AppText.headlineSmall(
            loc(context).addNodesAdded(added < 1 ? 1 : added)),
        AppGap.xl(),
        _nodeList(context),
        AppGap.xl(),
        AppText.titleMedium(loc(context).modalMoveChildNodesTitle),
        AppGap.sm(),
        AppText.bodyMedium(loc(context).modalMoveChildNodesDesc),
      ],
      actions: [_doneButton(context, primary: true)],
    );
  }

  /// What to do about the nodes that were found and not added.
  Widget _failedTroubleshooting(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText.titleMedium(loc(context).addNodesFailedTroubleshootTitle),
          AppGap.md(),
          AppBulletList(
            style: AppBulletStyle.number,
            children: [
              AppText.bodyMedium(loc(context).addNodesFailedTroubleshootDesc1),
              AppText.bodyMedium(loc(context).addNodesFailedTroubleshootDesc2),
              AppText.bodyMedium(loc(context).addNodesFailedTroubleshootDesc3),
            ],
          ),
        ],
      );

  // ---------------------------------------------------------------------------
  // Node list
  // ---------------------------------------------------------------------------

  /// Every node the session found, in the router's order, each with its
  /// outcome. All of them, whatever the outcome: a node left off the list is a
  /// node the user cannot tell happened.
  Widget _nodeList(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, node) in state.nodes.indexed) ...[
            if (i > 0) AppGap.sm(),
            _nodeCard(context, node),
          ],
        ],
      );

  Widget _nodeCard(BuildContext context, AddNodesNodeUIModel node) {
    final outcome = state.outcomeFor(node);
    final model = node.modelNumber;
    return AppNodeListCard(
      leading: DeviceImageHelper.getRouterImage(
          routerIconTestByModel(modelNumber: model ?? '')),
      title: model ?? node.bleMacAddress,
      // In words for every outcome: the check mark alone is not one a screen
      // reader can say, and the other three have no mark at all.
      description: switch (outcome) {
        AddNodesNodeOutcome.added => loc(context).addNodesStatusAdded,
        AddNodesNodeOutcome.joining => loc(context).addNodesStatusJoining,
        AddNodesNodeOutcome.failed => loc(context).addNodesStatusFailed,
        AddNodesNodeOutcome.notTried => loc(context).addNodesStatusNotTried,
      },
      trailing: outcome == AddNodesNodeOutcome.added
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

  /// A phase the router is working through: a spinner, what it is doing, the
  /// nodes found so far, and a cancel while a session is in progress. The
  /// notifier decides whether that cancel sends a `Stop()`.
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
              if (state.nodes.isNotEmpty) ...[
                AppGap.xl(),
                // The full column width, as on the result screens, rather than
                // each card's own.
                SizedBox(width: double.infinity, child: _nodeList(context)),
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
