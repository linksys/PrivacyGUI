import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_runtime.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_section.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_log_view.dart';

/// The route asks the mounted page to finish cleanup before leaving setup.
/// The callback is cleared on disposal; an unmounted page cannot authorize exit.
class AutoIPoEPnpExitGuard {
  Future<bool> Function()? onExit;
}

final autoIPoEPnpExitGuardProvider = Provider.autoDispose<AutoIPoEPnpExitGuard>(
  (ref) => AutoIPoEPnpExitGuard(),
);

/// PnP setup with verified completion and guarded recovery before exit.
class PnpIPoEView extends ConsumerStatefulWidget {
  const PnpIPoEView({super.key});

  @override
  ConsumerState<PnpIPoEView> createState() => _PnpIPoEViewState();
}

class _PnpIPoEViewState extends ConsumerState<PnpIPoEView> {
  bool _sending = false;
  bool _started = false;
  bool _leaving = false;
  bool _continuing = false;
  bool _recoveringSession = false;
  String? _requestId;
  AutoIPoESettings? _draft;
  AutoIPoEService? _attemptService;
  Object? _actionError;
  AutoIPoEService? _actionErrorService;
  bool _allowPnpExit = false;
  AutoIPoEPnpExitGuard? _exitGuard;

  bool get _supportsAutoIPoE =>
      mounted &&
      ref.read(deviceCapabilitiesProvider).has(DeviceCapability.autoIPoE);

  @override
  void initState() {
    super.initState();
    _exitGuard = ref.read(autoIPoEPnpExitGuardProvider);
    _exitGuard!.onExit = _preparePnpExit;
  }

  @override
  void dispose() {
    _exitGuard?.onExit = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoIPoEPnpExitGuardProvider);
    final supportsAutoIPoE =
        ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.autoIPoE);
    final editor =
        ref.watch(surfaceStrategyProvider).internetSettingsEditor(() {});
    ref.listen(autoIPoEPageProvider, (_, __) {
      if (_requestId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAdvance());
      }
    });
    final state = ref.watch(autoIPoEPageProvider);
    final submission = ref.watch(autoIPoESubmissionProvider);
    final rejection = ref.watch(autoIPoERejectionProvider);
    final snapshot = state.status.snapshot;
    final outcome = rejection != null
        ? AutoIPoEOutcome.rejected
        : snapshot.outcomeFor(submission);
    final readState = ref.watch(autoIPoEDataProvider);
    final readError = readState.error;
    if (!readState.isLoading) _recoverPnpSession(readError);
    _recoverPnpSession(_actionError, origin: _actionErrorService);
    final retryRead = outcome == AutoIPoEOutcome.pending && readError != null;
    final retry = _actionError != null ||
        retryRead ||
        outcome == AutoIPoEOutcome.failed ||
        outcome == AutoIPoEOutcome.rejected ||
        outcome == AutoIPoEOutcome.retryScheduled;
    final busy = _recoveringSession ||
        _leaving ||
        _sending ||
        _continuing ||
        state.status.saving ||
        snapshot.runtime.isBusy ||
        snapshot.outcomeFor(submission) == AutoIPoEOutcome.pending;
    // A resumed in-flight request is also execution, not a new editable form.
    // Latch this until the page is left so a terminal error cannot expose Apply.
    if (busy && !state.status.loading) _started = true;
    // Loading a page can briefly lack the stored request's snapshot. Once
    // reconciled, idle or completed work owned by an earlier visit must not
    // leave this page latched in progress with no navigation controls.
    if (!busy &&
        _requestId == null &&
        (outcome == AutoIPoEOutcome.idle ||
            outcome == AutoIPoEOutcome.succeeded) &&
        readError == null &&
        _actionError == null) {
      _started = false;
    }
    final pnpError = !_leaving &&
        _started &&
        (retry ||
            readError != null ||
            (!busy && outcome == AutoIPoEOutcome.idle));
    final l = loc(context);
    return UiKitPageView.withSliver(
      appBarStyle: UiKitAppBarStyle.none,
      onBackTap: () => context.pop(),
      scrollable: true,
      onRefresh: supportsAutoIPoE
          ? () async {
              if (!_supportsAutoIPoE) return;
              await ref
                  .read(autoIPoEPageProvider.notifier)
                  .fetch(forceRemote: true, updateStatusOnly: state.isDirty);
            }
          : null,
      child: (context, constraints) {
        if (!supportsAutoIPoE) return _pnpBack(context);
        if (state.status.loading) return const Center(child: AppLoader());
        if (!snapshot.capabilities.isSupported) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.bodyMedium(l.failedToLoadSettings),
              if (snapshot.runtime.needsResetBeforeLeaving) ...[
                AppGap.md(),
                AppText.bodyMedium(l.autoIpoeResetBeforeSwitching),
              ],
              if (_actionError ?? state.status.error case final error?) ...[
                AppGap.md(),
                AppText.bodyMedium(localizeServiceError(context, error)),
              ],
              AppGap.lg(),
              if (_leaving)
                const Center(child: AppLoader())
              else
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppButton.text(
                      identifier: 'auto-ipoe-pnp-retry-settings',
                      label: l.retry,
                      onTap: () {
                        if (!_supportsAutoIPoE) return;
                        ref
                            .read(autoIPoEPageProvider.notifier)
                            .fetch(forceRemote: true);
                      },
                    ),
                    if (snapshot.runtime.needsResetBeforeLeaving &&
                        editor != null)
                      AppButton.primary(
                        identifier: 'auto-ipoe-pnp-recovery-reset',
                        label: l.autoIpoeReset,
                        onTap: _back,
                      )
                    else
                      _pnpBack(context),
                  ],
                ),
            ],
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText.headlineSmall(l.autoIpoeOpenSettings),
                  if (!_started) ...[
                    AppGap.lg(),
                    AppText.bodyMedium(l.autoIpoePnpDescription),
                  ],
                  AppGap.xl(),
                  if (!_started)
                    AutoIPoESection(
                      settings: state.current,
                      status: snapshot.runtime,
                      capabilities: snapshot.capabilities,
                      isEditing: editor != null && !busy,
                      showParameterHints: false,
                      onChanged: ref
                          .read(autoIPoEPageProvider.notifier)
                          .updateSettings,
                    ),
                  if (_leaving) ...[
                    AppGap.lg(),
                    const Center(child: AppLoader()),
                  ],
                  if (_started && _actionError == null && !_leaving) ...[
                    AppGap.lg(),
                    buildAutoIPoERuntime(
                      context,
                      ref,
                      snapshot,
                      _sending && outcome == AutoIPoEOutcome.idle
                          ? AutoIPoEOutcome.pending
                          : outcome,
                      submission,
                      inline: true,
                      showRecoveryActions: false,
                    ),
                  ],
                  if (_started) ...[
                    AppGap.lg(),
                    AutoIPoELogView(
                      compact: true,
                      log: snapshot.log,
                      onRefresh: () async =>
                          _supportsAutoIPoE &&
                          await ref
                                  .read(autoIPoEDataProvider.notifier)
                                  .refresh() !=
                              null,
                    ),
                  ],
                  if (_actionError != null) ...[
                    AppGap.lg(),
                    AppText.bodyMedium(
                      localizeServiceError(context, _actionError!),
                    ),
                  ],
                  if (!_leaving && (!_started || pnpError)) ...[
                    AppGap.xxxl(),
                    Wrap(
                      spacing: AppSpacing.md,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!_started)
                          AppButton.primary(
                            identifier: 'auto-ipoe-pnp-continue',
                            label: l.autoIpoeExecute,
                            onTap: editor == null ? null : _next,
                          ),
                        _pnpBack(context),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _ownsCurrentSession(AutoIPoEService service) {
    if (!_supportsAutoIPoE) return false;
    try {
      if (!identical(service, ref.read(autoIPoEServiceProvider))) return false;
      service.checkConnection();
      return true;
    } on NotAuthenticatedError {
      // A stable client can have been rebound since this service was created.
      return false;
    } on ResourceNotFoundError {
      return false;
    }
  }

  void _recoverPnpSession(Object? error, {AutoIPoEService? origin}) {
    if (!_supportsAutoIPoE ||
        _recoveringSession ||
        (error is! NotAuthenticatedError &&
            error is! InvalidSessionTokenError &&
            error is! SessionTokenExpiredError)) {
      return;
    }
    final service = ref.read(autoIPoEServiceProvider);
    if ((origin != null && !identical(origin, service)) ||
        !_ownsCurrentSession(service)) {
      return;
    }
    _recoveringSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Do not end a replacement session for an error from the previous one.
      if (!_ownsCurrentSession(service) ||
          ref.read(autoIPoEDataProvider).isLoading ||
          (!identical(error, ref.read(autoIPoEDataProvider).error) &&
              !identical(error, _actionError))) {
        setState(() => _recoveringSession = false);
        return;
      }
      // Reauthentication is not the user's Back/cancel action. Retain the
      // submitted request for read-only reconciliation after the next login;
      // neither the exit guard nor the dirty guard may issue Reset here.
      _allowPnpExit = true;
      _requestId = null;
      ref.read(autoIPoEPageProvider.notifier).revert();
      await ref.read(authProvider.notifier).logout(cause: EndCause.sessionLost);
      if (mounted) context.go(RoutePath.localLoginPassword);
    });
  }

  Future<void> _next() async {
    if (!_supportsAutoIPoE) return;
    if (ref.read(surfaceStrategyProvider).internetSettingsEditor(() {}) ==
        null) {
      return;
    }
    if (_sending || _continuing || _leaving || _recoveringSession) return;
    setState(() => _started = true);
    final page = ref.read(autoIPoEPageProvider);
    final submission = ref.read(autoIPoESubmissionProvider);
    final outcome = page.status.snapshot.outcomeFor(submission);
    if (outcome == AutoIPoEOutcome.pending ||
        page.status.snapshot.runtime.isBusy) {
      // A lost reply is still an in-flight request: Retry resumes observation.
      ref.read(autoIPoEDataProvider.notifier).continueChecking();
      await ref.read(autoIPoEDataProvider.notifier).refresh();
      return;
    }
    if (!page.isDirty &&
        outcome == AutoIPoEOutcome.succeeded &&
        submission?.reset == false &&
        ref.read(autoIPoERejectionProvider) == null) {
      await _continuePnp();
      return;
    }
    setState(() {
      _sending = true;
      _actionError = null;
    });
    _requestId = null;
    _draft = page.current;
    final service = ref.read(autoIPoEServiceProvider);
    _attemptService = service;
    try {
      await ref.read(autoIPoEPageProvider.notifier).saveForPnp();
      if (!_ownsCurrentSession(service)) return;
      final current = ref.read(autoIPoESubmissionProvider);
      if (current?.reset == false &&
          current?.requestId != submission?.requestId) {
        _requestId = current!.requestId;
      }
    } catch (e) {
      if (mounted && _ownsCurrentSession(service)) {
        setState(() {
          _actionError = e;
          _actionErrorService = service;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    await _maybeAdvance();
  }

  Future<void> _maybeAdvance() async {
    if (!_supportsAutoIPoE ||
        _sending ||
        _continuing ||
        _leaving ||
        _recoveringSession ||
        _requestId == null) {
      return;
    }
    final service = _attemptService;
    if (service == null || !_ownsCurrentSession(service)) return;
    final page = ref.read(autoIPoEPageProvider);
    final submission = ref.read(autoIPoESubmissionProvider);
    if (submission?.requestId != _requestId ||
        submission?.reset != false ||
        page.current != _draft ||
        page.status.error != null ||
        ref.read(autoIPoEDataProvider).hasError ||
        ref.read(autoIPoERejectionProvider) != null) {
      return;
    }
    if (page.status.snapshot.outcomeFor(submission) ==
        AutoIPoEOutcome.succeeded) {
      await _continuePnp();
    }
  }

  Future<void> _continuePnp() async {
    if (!_supportsAutoIPoE || _continuing) return;
    final service = ref.read(autoIPoEServiceProvider);
    setState(() {
      _continuing = true;
      _actionError = null;
    });
    _requestId = null;
    try {
      await ref.read(pnpProvider.notifier).startPostLoginFlow();
      if (_ownsCurrentSession(service)) {
        // Only verified forward completion may leave without restoring WAN.
        ref.read(autoIPoEPageProvider.notifier).markAsSaved();
        _allowPnpExit = true;
        context.go(RoutePath.pnp);
      } else if (mounted) {
        setState(() => _continuing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _continuing = false;
          if (_ownsCurrentSession(service)) {
            _actionError = e;
            _actionErrorService = service;
          }
        });
      }
    }
  }

  Future<void> _back() async {
    if (await _preparePnpExit() && mounted) {
      context.goNamed(RouteNamed.pnpIspTypeSelection);
    }
  }

  Future<bool> _preparePnpExit() async {
    if (_allowPnpExit) return true;
    if (!_supportsAutoIPoE) {
      if (!mounted) return false;
      _requestId = null;
      _draft = null;
      _attemptService = null;
      ref.read(autoIPoEPageProvider.notifier).revert();
      _allowPnpExit = true;
      return true;
    }
    if (_leaving || _sending || _continuing) return false;
    if (ref.read(surfaceStrategyProvider).internetSettingsEditor(() {}) ==
        null) {
      ref.read(autoIPoEPageProvider.notifier).revert();
      _allowPnpExit = true;
      return true;
    }
    final hadAttempt = _started;
    final service = ref.read(autoIPoEServiceProvider);
    setState(() {
      _leaving = true;
      _actionError = null;
    });
    // Prevent a late successful Apply callback from advancing onboarding
    // while the user's explicit Back action restores the DHCP baseline.
    _requestId = null;
    try {
      await ref
          .read(autoIPoEDataProvider.notifier)
          .leavePnp(resetIfIdle: hadAttempt);
      if (!mounted) return false;
      if (!_supportsAutoIPoE) return await _preparePnpExit();
      if (!_ownsCurrentSession(service)) return false;
      // Cleanup is complete, so the route's subsequent dirty guard has nothing
      // left to discard and cannot keep the user on a half-exited page.
      ref.read(autoIPoEPageProvider.notifier).revert();
      _allowPnpExit = true;
      return true;
    } catch (e) {
      if (mounted && _ownsCurrentSession(service)) {
        setState(() {
          _started = true;
          _actionError = e;
          _actionErrorService = service;
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  Widget _pnpBack(BuildContext context) => TextButton(
        key: const ValueKey('auto-ipoe-pnp-back'),
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          overlayColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: _leaving && _supportsAutoIPoE ? null : _back,
        child: Text(loc(context).back),
      );
}
