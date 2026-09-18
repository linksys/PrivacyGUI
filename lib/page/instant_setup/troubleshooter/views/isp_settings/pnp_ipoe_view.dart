import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/auto_ipoe_section.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_notifier.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_reconciliation_coordinator.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_optional_pane.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_recovery_ui.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

bool shouldShowPnpIPoEEditor({required bool isRecovering}) => !isRecovering;

class PnpIpoeView extends ConsumerStatefulWidget {
  const PnpIpoeView({super.key});

  @override
  ConsumerState<PnpIpoeView> createState() => _PnpIpoeViewState();
}

class _PnpIpoeViewState extends ConsumerState<PnpIpoeView> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isRecovering = false;
  int _recoveryGeneration = 0;
  String? _errorMessage;
  AutoIPoEIssue? _issue;
  AutoIPoEReconciliationProgress _progress =
      const AutoIPoEReconciliationProgress.initial();

  @override
  void initState() {
    super.initState();
    // Off the life-cycle stack: the first thing this does is seed the draft in
    // the provider, and Riverpod refuses a write made from initState.
    Future.microtask(_loadCapabilities);
  }

  Future<void> _loadCapabilities() async {
    final notifier = ref.read(autoIPoEProvider.notifier);
    // This flow always starts from Auto, whatever the router is configured with,
    // so the draft is seeded here rather than inherited. It has to happen before
    // the read: the fallback editor below would otherwise show whatever a
    // previous screen left in the provider.
    notifier.updateSettings(const AutoIPoESettings.init().copyWith(
      isEnabled: true,
      selectedMode: AutoIPoEMode.auto,
    ));
    try {
      final capabilities = await notifier.fetchCapabilities();
      final supportedModes = capabilities.supportedModes
          .where((mode) => mode != AutoIPoEMode.disabled)
          .toList();
      final current = ref.read(autoIPoEProvider).settings;
      final selectedMode = supportedModes.contains(current.selectedMode)
          ? current.selectedMode
          : (supportedModes.isNotEmpty
              ? supportedModes.first
              : AutoIPoEMode.auto);
      if (!mounted) {
        return;
      }
      notifier.updateSettings(
        current.copyWith(isEnabled: true, selectedMode: selectedMode),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      logger.w(
        '[PnP Troubleshooter]: Failed to fetch Auto-IPoE capabilities, '
        'falling back to auto-only editor. $error\n$stackTrace',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onNext() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _issue = null;
      _progress = const AutoIPoEReconciliationProgress.initial();
    });
    ref.read(autoIPoEProvider.notifier).updateRuntime(
          const AutoIPoEStatus.init(),
          const AutoIPoELog.init(),
        );
    logger.i('[PnP Troubleshooter]: Open IPoE save path');
    var newState = ref.read(internetSettingsProvider).copyWith();
    newState = newState.copyWith(
      ipv4Setting: newState.ipv4Setting.copyWith(
        ipv4ConnectionType: WanType.ipoe.type,
      ),
    );
    final result = await context.pushNamed(
      RouteNamed.pnpIspSaveSettings,
      extra: {
        'newSettings': newState,
        'autoIPoESettings': buildEnabledAutoIPoESettings(
          ref.read(autoIPoEProvider).settings,
        ),
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      if (result is AutoIPoEIssue) {
        _issue = result;
        _isRecovering = result.retryable;
      } else if (result is String) {
        _errorMessage = result;
      }
    });
    if (result is AutoIPoEIssue && result.isTerminal && mounted) {
      await showAutoIPoETerminalFailureDialog(context, result);
    } else if (result is AutoIPoEIssue &&
        result.recoveryAction == AutoIPoERecoveryAction.continueChecking &&
        mounted) {
      // Apply has already been dispatched. Follow that one operation in the
      // background; this path never calls Set or Apply.
      unawaited(_reconcileExistingApply());
    }
  }

  Future<void> _reconcileExistingApply() async {
    if (_isSubmitting) {
      return;
    }
    final generation = ++_recoveryGeneration;
    setState(() {
      _isSubmitting = true;
    });
    // The generation fence is the whole reason this is a closure: every await
    // inside the coordinator asks again whether this attempt is still the one on
    // screen, so a superseded run reports Cancelled instead of writing over what
    // replaced it.
    bool isCurrent() => mounted && generation == _recoveryGeneration;
    final coordinator = ref.read(autoIPoEReconciliationCoordinatorProvider);
    try {
      final outcome = await coordinator.followPnpSetup(
        expectedMode: ref.read(autoIPoEProvider).settings.selectedMode,
        isCurrent: isCurrent,
        // Carries over what reconciliation has already observed, the way the
        // old local progress field did.
        initialStatus: ref.read(autoIPoEProvider).status,
        // Same native status check and retry budget as DHCP/PPPoE. ICC refreshes
        // asynchronously after tunnel hotplug events.
        verifyInternet: () =>
            ref.read(pnpProvider.notifier).checkInternetConnection(30),
        onProgress: (progress) => _updateProgress(progress, generation),
        onRuntime: (status, log) {
          if (!isCurrent()) {
            return;
          }
          ref.read(autoIPoEProvider.notifier).updateRuntime(status, log);
        },
        onPollingWindowEnded: (issue) {
          if (!isCurrent()) {
            return;
          }
          // A bounded window ended while the same worker may still be running.
          // Stay in the compact progress UI; nothing here re-sends Apply.
          setState(() {
            _isRecovering = true;
            _issue = issue;
          });
        },
      );
      if (!isCurrent()) {
        return;
      }
      switch (outcome) {
        case AutoIPoEReconciliationCompleted():
          // Let the determinate indicator visibly reach 5/5 before this route is
          // replaced by the PnP configuration screen.
          await Future<void>.delayed(const Duration(milliseconds: 800));
          if (mounted && generation == _recoveryGeneration) {
            context.goNamed(RouteNamed.pnp);
          }
        case AutoIPoEReconciliationNoInternet():
          if (mounted) {
            context.goNamed(RouteNamed.pnpNoInternetConnection);
          }
        case AutoIPoEReconciliationFailed(
            issue: final issue,
            terminal: final terminal
          ):
          setState(() {
            // Retry and Edit are safe to reveal only because the worker ended.
            _isRecovering = !terminal;
            _issue = issue;
          });
          if (terminal && mounted) {
            await showAutoIPoETerminalFailureDialog(context, issue);
          }
        case AutoIPoEReconciliationCancelled():
          break;
      }
    } finally {
      if (isCurrent()) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _updateProgress(
    AutoIPoEReconciliationProgress next,
    int generation,
  ) {
    if (!mounted || generation != _recoveryGeneration) {
      return;
    }
    final advanced = _progress.advanceTo(next);
    if (advanced == _progress) {
      return;
    }
    setState(() {
      _progress = advanced;
    });
  }

  void _editSettings() {
    _recoveryGeneration++;
    setState(() {
      // Edit is exposed only after the previous worker has ended. Reveal the
      // preserved fields without dispatching another Apply automatically.
      _isRecovering = false;
      _isSubmitting = false;
      if (_issue?.fieldGroup == AutoIPoEFieldGroup.none) {
        _issue = null;
      }
    });
  }

  void _retrySetup() {
    // The previous worker has ended. Reveal the preserved values and require
    // one explicit Next press to dispatch a fresh Apply.
    // Never resubmit automatically from a recovery/status callback.
    _recoveryGeneration++;
    setState(() {
      _isRecovering = false;
      _isSubmitting = false;
      _issue = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppFullScreenSpinner();
    }
    // The provider owns the whole Auto-IPoE picture: the capabilities describe
    // the router, the settings are the draft being edited, and the status and log
    // are what reconciliation has observed. This screen no longer keeps copies.
    final autoIPoEState = ref.watch(autoIPoEProvider);
    final showEditor = shouldShowPnpIPoEEditor(isRecovering: _isRecovering);

    return StyledAppPageView(
      title: 'IPoE',
      scrollable: true,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(loc(context).autoIpoePnpDescription),
          const AppGap.large3(),
          if (_errorMessage != null) ...[
            AppText.bodyLarge(
              _errorMessage!,
              color: Theme.of(context).colorScheme.error,
            ),
            const AppGap.large3(),
          ],
          if (_isRecovering) ...[
            AutoIPoEOptionalPane(
              compactProgress: true,
              progress: _progress,
              state: autoIPoEState,
              shouldTrackRuntime: false,
              awaitingCompletion: true,
              issue: _issue,
              isChecking: _isSubmitting,
              onContinueChecking: _reconcileExistingApply,
              onRetry: _retrySetup,
              onEditSettings: _editSettings,
              onAwaitingCompletionChanged: (_) {},
            ),
            const AppGap.large3(),
          ],
          if (showEditor) ...[
            AutoIPoESection(
              settings: autoIPoEState.settings,
              status: const AutoIPoEStatus.init(),
              capabilities: autoIPoEState.capabilities,
              isEditing: true,
              highlightedFieldGroup:
                  _issue?.fieldGroup ?? AutoIPoEFieldGroup.none,
              onChanged: (settings) {
                ref
                    .read(autoIPoEProvider.notifier)
                    .updateSettings(settings.copyWith(isEnabled: true));
                setState(() {
                  _issue = null;
                });
              },
            ),
            const AppGap.large3(),
            AppFilledButton(
              loc(context).next,
              onTap: _isSubmitting || _isRecovering ? null : _onNext,
            ),
          ],
        ],
      ),
    );
  }
}
