import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html'
    if (dart.library.io) 'package:privacy_gui/providers/remote_access/stub_html.dart'
    as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/framework/mode/session_request.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/remote_assistance/models/remote_assistance_confirm_state.dart';
import 'package:privacy_gui/page/remote_assistance/providers/remote_assistance_confirm_notifier.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class RemoteAssistanceConfirmView extends ConsumerStatefulWidget {
  final String sessionId;
  final String token;
  final bool sessionEnded;

  const RemoteAssistanceConfirmView({
    super.key,
    required this.sessionId,
    required this.token,
    this.sessionEnded = false,
  });

  @override
  ConsumerState<RemoteAssistanceConfirmView> createState() =>
      _RemoteAssistanceConfirmViewState();
}

class _RemoteAssistanceConfirmViewState
    extends ConsumerState<RemoteAssistanceConfirmView> {
  bool get _hasValidSessionId => widget.sessionId.isNotEmpty;
  bool get _hasToken => widget.token.isNotEmpty;
  bool get _hasRequiredParams => _hasValidSessionId && _hasToken;

  RemoteAssistanceConfirmNotifier get _notifier =>
      ref.read(remoteAssistanceConfirmProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Strip token from URL to prevent leakage via history/Referer
    if (kIsWeb && widget.token.isNotEmpty) {
      html.window.history.replaceState(
        null,
        '',
        '${RoutePath.remoteAssistanceConfirm}?session=${widget.sessionId}',
      );
    }
    // Auto-validate if all required params are present
    if (_hasRequiredParams) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateToken();
      });
    }
  }

  void _validateToken() {
    if (!_hasRequiredParams) return;
    _notifier.validate(sessionId: widget.sessionId, token: widget.token);
  }

  Future<void> _connect() async {
    final state = ref.read(remoteAssistanceConfirmProvider);
    if (!state.canConnect) return;

    _notifier.beginConnect();

    try {
      await doSomethingWithSpinner(
        context,
        _doConnect(state),
      );

      // Navigate AFTER spinner completes to avoid orphaned dialog
      if (!mounted) return;
      context.goNamed(RouteNamed.uspDashboard);
    } catch (e) {
      logger.e('[RA] Connection failed: $e');
      if (!mounted) return;
      _notifier.connectFailed('Connection failed: ${e.toString()}');
    }
  }

  /// Open the session. The *how* belongs to cause 3, not to this view.
  ///
  /// #1474 phase 9 moved the transport config, `activate()` and the
  /// `updateSessionInfo()` bookkeeping into `RemoteSessionStrategy.start()`, which
  /// is the remote half of the same member `AuthNotifier.localLogin` reaches for the
  /// local half. This view keeps what is genuinely its own: the spinner, and the
  /// "Connection failed" surface in [_connect] that catches whatever `start` throws.
  /// The validated session and its countdown are `remoteAssistanceConfirmProvider`'s.
  ///
  /// Via `AuthNotifier.openSession` because `start` takes a `Ref` and a widget holds
  /// a `WidgetRef`; see that method for why the funnel lives there.
  Future<void> _doConnect(RemoteAssistanceConfirmState state) async {
    await ref.read(authProvider.notifier).openSession(
          SupportSessionRequest(
            sessionId: widget.sessionId,
            token: widget.token,
            sessionInfo: state.sessionInfo,
            remainingSeconds: state.remainingSeconds,
          ),
        );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  Widget _buildSessionStatusCard(
      BuildContext context, RemoteAssistanceConfirmState state) {
    final sessionInfo = state.sessionInfo!;
    final remainingSeconds = state.remainingSeconds;
    final colorScheme = Theme.of(context).colorScheme;

    final statusColor = switch (sessionInfo.status) {
      GRASessionStatus.active => colorScheme.primary,
      GRASessionStatus.pending => colorScheme.tertiary,
      GRASessionStatus.initiate => colorScheme.secondary,
      GRASessionStatus.invalid => colorScheme.error,
    };

    // Get router image from model number
    final iconName =
        routerIconTestByModel(modelNumber: sessionInfo.modelNumber);
    final routerImage = DeviceImageHelper.getRouterImage(iconName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Router image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: routerImage,
                fit: BoxFit.contain,
              ),
            ),
          ),
          AppGap.lg(),
          // Device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleMedium(sessionInfo.modelNumber),
                AppGap.xs(),
                AppText.bodySmall(
                  sessionInfo.serialNumber,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                AppGap.md(),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      AppGap.xs(),
                      AppText.labelSmall(
                        RemoteAssistanceConfirmNotifier.statusText(
                            sessionInfo.status),
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                if (remainingSeconds != null && remainingSeconds > 0) ...[
                  AppGap.sm(),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      AppGap.xs(),
                      AppText.bodySmall(
                        _formatDuration(remainingSeconds),
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(remoteAssistanceConfirmProvider);

    // Show session ended view
    if (widget.sessionEnded) {
      return _buildSessionEndedView(context, colorScheme);
    }

    // Show error view if required params are missing
    if (!_hasRequiredParams) {
      return _buildMissingParamsView(context, colorScheme);
    }

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      child: (context, constraints) => Center(
        child: SizedBox(
          width: context.colWidth(4),
          // Keyed by the view state, so the real-router RA spec waits for
          // `validated` (or sees `error`) structurally rather than by matching
          // "Session validated. Ready to connect.", which is unlocalized copy and
          // will not stay that way.
          //
          // `validated` is not only "before Connect": a Connect that fails comes
          // back to it, with the error box shown (see `_connect`). After tapping
          // Connect, a spec must wait for the dashboard OR the error box's own
          // hook, `ra-confirm-error-message` — not for this hook to leave
          // `validated`, which a failure never does.
          child: AppCard(
            identifier: 'ra-confirm-state-${state.phase.name}',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.headlineSmall(loc(context).remoteAssistance),
                AppGap.xxxl(),
                AppText.bodyMedium(
                  'Session ID: ${widget.sessionId}',
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                AppGap.md(),
                AppText.bodyMedium(
                  'Environment: ${cloudEnvironmentConfig[kCloudBase]}',
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                if (state.phase == RemoteAssistanceConfirmPhase.validating) ...[
                  AppGap.xxxl(),
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        AppGap.md(),
                        AppText.bodyMedium(loc(context).validatingSession),
                      ],
                    ),
                  ),
                ],
                if (state.errorMessage != null) ...[
                  AppGap.lg(),
                  // Keyed on the box, not on the view state: a failed Connect
                  // shows it while the state stays `validated` (see the card
                  // hook above), so this is the only structural sign of that
                  // failure. A spec racing it against the dashboard can report
                  // the message instead of timing out.
                  Semantics(
                    identifier: 'ra-confirm-error-message',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error),
                          AppGap.md(),
                          Expanded(
                            child: AppText.bodyMedium(
                              state.errorMessage!,
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppGap.md(),
                  AppButton(
                    label: loc(context).retry,
                    variant: SurfaceVariant.tonal,
                    size: AppButtonSize.small,
                    onTap: _validateToken,
                  ),
                ],
                if (state.sessionInfo != null &&
                    state.sessionInfo!.modelNumber.isNotEmpty) ...[
                  AppGap.lg(),
                  _buildSessionStatusCard(context, state),
                ],
                if (state.canConnect) ...[
                  AppGap.xxxl(),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label:
                          state.phase == RemoteAssistanceConfirmPhase.connecting
                              ? 'Connecting...'
                              : 'Connect',
                      identifier: 'ra-confirm-connect',
                      variant: SurfaceVariant.highlight,
                      size: AppButtonSize.small,
                      onTap:
                          state.phase == RemoteAssistanceConfirmPhase.connecting
                              ? null
                              : _connect,
                    ),
                  ),
                  AppGap.md(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      AppGap.sm(),
                      AppText.bodySmall(
                        'Session validated. Ready to connect.',
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingParamsView(
      BuildContext context, ColorScheme colorScheme) {
    final missingParams = <String>[];
    if (!_hasValidSessionId) missingParams.add('session');
    if (!_hasToken) missingParams.add('token');

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      child: (context, constraints) => Center(
        child: SizedBox(
          width: context.colWidth(4),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colorScheme.error,
                ),
                AppGap.xl(),
                AppText.headlineSmall(
                  'Missing Parameters',
                  color: colorScheme.error,
                ),
                AppGap.lg(),
                AppText.bodyMedium(
                  'The following required parameters are missing:\n'
                  '${missingParams.join(', ')}',
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                AppGap.xl(),
                AppText.bodySmall(
                  'Expected URL format:\n'
                  '/remote-assistance?session=<id>&token=<token>',
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionEndedView(BuildContext context, ColorScheme colorScheme) {
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      child: (context, constraints) => Center(
        child: SizedBox(
          width: context.colWidth(4),
          child: AppCard(
            // The terminal surface an agent lands on after End Session — or after
            // any automatic ending (#1323). A separate view, not a phase,
            // so it has its own hook rather than a fifth `ra-confirm-state-*`.
            identifier: 'ra-confirm-ended',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: colorScheme.primary,
                ),
                AppGap.xl(),
                AppText.headlineSmall(
                  'Session Ended',
                  textAlign: TextAlign.center,
                ),
                AppGap.lg(),
                AppText.bodyMedium(
                  'The remote assistance session has been disconnected.',
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                AppGap.xxxl(),
                AppText.bodySmall(
                  'You can close this window or start a new session.',
                  textAlign: TextAlign.center,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
