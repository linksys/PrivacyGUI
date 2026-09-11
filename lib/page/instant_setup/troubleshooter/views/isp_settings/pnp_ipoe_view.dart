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
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_internet_settings_bridge.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_optional_pane.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_recovery_ui.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

bool shouldShowPnpIPoEEditor({required bool isRecovering}) => !isRecovering;

/// New Auto-IPoE runtimes perform their own multi-target connectivity check.
/// Older firmware has no structured completion signal, so it keeps the
/// LinksysNow probe as a compatibility fallback.
bool shouldRunLegacyPnpIPoEConnectivityProbe(AutoIPoEStatus status) =>
    !status.terminalResultSupported && !status.hasVerifiedBackendConnectivity;

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
  AutoIPoEStatus _progressStatus = const AutoIPoEStatus.init();
  AutoIPoELog _progressLog = const AutoIPoELog.init();
  AutoIPoEReconciliationProgress _progress =
      const AutoIPoEReconciliationProgress.initial();
  AutoIPoECapabilities _capabilities = const AutoIPoECapabilities.init();
  AutoIPoESettings _settings = const AutoIPoESettings.init().copyWith(
    isEnabled: true,
    selectedMode: AutoIPoEMode.auto,
  );

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final capabilities =
          await ref.read(autoIPoEServiceProvider).getCapabilities();
      final supportedModes = capabilities.supportedModes
          .where((mode) => mode != AutoIPoEMode.disabled)
          .toList();
      final selectedMode = supportedModes.contains(_settings.selectedMode)
          ? _settings.selectedMode
          : (supportedModes.isNotEmpty
              ? supportedModes.first
              : AutoIPoEMode.auto);
      if (!mounted) {
        return;
      }
      setState(() {
        _capabilities = capabilities;
        _settings = _settings.copyWith(
          isEnabled: true,
          selectedMode: selectedMode,
        );
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
      _progressStatus = const AutoIPoEStatus.init();
      _progressLog = const AutoIPoELog.init();
      _progress = const AutoIPoEReconciliationProgress.initial();
    });
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
        'autoIPoESettings': buildEnabledAutoIPoESettings(_settings),
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
    final bridge = ref.read(autoIPoEInternetSettingsBridgeProvider);
    var latestStatus = _progressStatus;
    try {
      while (mounted && generation == _recoveryGeneration) {
        try {
          await bridge.waitForPnpIPoESetupCompletion(
            expectedMode: _settings.selectedMode,
            useStructuredProgress: true,
            onReconciliationProgress: (progress) {
              _updateProgress(progress, generation);
            },
            onProgress: (status, log) {
              latestStatus = status;
              if (!mounted || generation != _recoveryGeneration) {
                return;
              }
              setState(() {
                _progressStatus = status;
                _progressLog = log;
              });
            },
          );
          if (shouldRunLegacyPnpIPoEConnectivityProbe(latestStatus)) {
            await bridge.waitForPnpIPoEInternetConnectivity(
              shouldContinue: () =>
                  mounted && generation == _recoveryGeneration,
              onReconciliationProgress: (progress) {
                _updateProgress(progress, generation);
              },
            );
          }
          // Use the same native status check/retry budget as DHCP/PPPoE.
          // ICC is refreshed asynchronously after tunnel hotplug events.
          await ref.read(pnpProvider.notifier).checkInternetConnection(30);
          // Let the determinate indicator visibly reach 5/5 before this
          // route is replaced by the PnP configuration screen.
          await Future<void>.delayed(const Duration(milliseconds: 800));
          if (mounted && generation == _recoveryGeneration) {
            context.goNamed(RouteNamed.pnp);
          }
          return;
        } on AutoIPoERecoveryPending catch (error) {
          if (error.issue.recoveryAction !=
              AutoIPoERecoveryAction.continueChecking) {
            rethrow;
          }
          if (!mounted || generation != _recoveryGeneration) {
            return;
          }
          // A bounded polling window ended while the same worker may still be
          // running. Continue read-only reconciliation under the same compact
          // progress UI; never issue Set or Apply here.
          setState(() {
            _isRecovering = true;
            _issue = error.issue;
          });
        }
      }
    } on ExceptionNoInternetConnection {
      if (mounted && generation == _recoveryGeneration) {
        context.goNamed(RouteNamed.pnpNoInternetConnection);
      }
    } on TimeoutException catch (error, stackTrace) {
      logger.w(
        '[PnP Troubleshooter]: Post-IPoE Internet connectivity did not '
        'recover within the bounded retry window',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted && generation == _recoveryGeneration) {
        context.goNamed(RouteNamed.pnpNoInternetConnection);
      }
    } on AutoIPoETerminalFailure catch (error) {
      if (!mounted || generation != _recoveryGeneration) {
        return;
      }
      setState(() {
        _isRecovering = false;
        _issue = error.issue;
      });
      await showAutoIPoETerminalFailureDialog(context, error.issue);
    } on AutoIPoERecoveryPending catch (error) {
      // Only a real retrySetup failure reaches this branch. The worker ended,
      // so it is safe to reveal Retry/Edit actions.
      if (mounted && generation == _recoveryGeneration) {
        setState(() {
          _isRecovering = true;
          _issue = error.issue;
        });
      }
    } catch (error) {
      final issue = AutoIPoEIssueMapper.from(
        error: error,
        mode: _settings.selectedMode,
      );
      if (!mounted || generation != _recoveryGeneration) {
        return;
      }
      setState(() {
        _isRecovering = issue.retryable;
        _issue = issue;
      });
      if (issue.isTerminal) {
        await showAutoIPoETerminalFailureDialog(context, issue);
      }
    } finally {
      if (mounted && generation == _recoveryGeneration) {
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
              state: AutoIPoEState(
                capabilities: _capabilities,
                settings: _settings,
                status: _progressStatus,
                log: _progressLog,
              ),
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
              settings: _settings,
              status: const AutoIPoEStatus.init(),
              capabilities: _capabilities,
              isEditing: true,
              highlightedFieldGroup:
                  _issue?.fieldGroup ?? AutoIPoEFieldGroup.none,
              onChanged: (settings) {
                setState(() {
                  _settings = settings.copyWith(isEnabled: true);
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
