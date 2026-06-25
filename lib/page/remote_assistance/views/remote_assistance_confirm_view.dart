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
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
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

enum _ViewState { idle, validating, validated, connecting, error }

class _RemoteAssistanceConfirmViewState
    extends ConsumerState<RemoteAssistanceConfirmView> {
  _ViewState _viewState = _ViewState.idle;
  String? _errorMessage;
  GRASessionInfo? _sessionInfo;
  Timer? _countdownTimer;
  int? _remainingSeconds;

  bool get _hasValidSessionId => widget.sessionId.isNotEmpty;
  bool get _hasToken => widget.token.isNotEmpty;
  bool get _hasRequiredParams => _hasValidSessionId && _hasToken;

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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _canConnect =>
      _viewState == _ViewState.validated &&
      _sessionInfo != null &&
      _sessionInfo!.status == GRASessionStatus.active;

  Future<void> _validateToken() async {
    if (!_hasRequiredParams) return;

    setState(() {
      _viewState = _ViewState.validating;
      _errorMessage = null;
    });

    try {
      final service = ref.read(remoteAssistanceServiceProvider);
      final sessionInfo = await service
          .fetchSessionInfoForCA(
            sessionToken: widget.token,
            sessionId: widget.sessionId,
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (sessionInfo.status == GRASessionStatus.invalid) {
        setState(() {
          _viewState = _ViewState.error;
          _errorMessage = 'Session is invalid or expired';
          _sessionInfo = sessionInfo;
        });
        return;
      }

      if (sessionInfo.status != GRASessionStatus.active) {
        setState(() {
          _viewState = _ViewState.error;
          _errorMessage =
              'Session is not active (${_statusToText(sessionInfo.status)})';
          _sessionInfo = sessionInfo;
        });
        return;
      }

      setState(() {
        _viewState = _ViewState.validated;
        _sessionInfo = sessionInfo;
        _remainingSeconds = sessionInfo.expiredIn.abs();
      });

      _startCountdown();
      logger.d('[RA] Session validated: ${sessionInfo.status}, '
          'expires in ${_remainingSeconds}s');
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _viewState = _ViewState.error;
        _errorMessage = 'Connection timed out. Please try again.';
      });
    } on ServiceError catch (e) {
      if (!mounted) return;
      setState(() {
        _viewState = _ViewState.error;
        _errorMessage = _mapServiceError(e);
      });
    } catch (e) {
      logger.e('[RA] Validate failed: $e');
      if (!mounted) return;
      setState(() {
        _viewState = _ViewState.error;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  String _mapServiceError(ServiceError error) {
    return switch (error) {
      SessionTokenExpiredError() => 'Token expired or invalid',
      UnauthorizedError() => 'Unauthorized - invalid token',
      ResourceNotFoundError() => 'Session not found',
      NetworkError(:final detail) =>
        'Network error${detail != null ? ': $detail' : ' - please try again'}',
      InvalidInputError(:final detail) =>
        'Invalid input${detail != null ? ': $detail' : ''}',
      UnexpectedError(:final detail) =>
        'Validation failed${detail != null ? ': $detail' : ''}',
      _ => 'Validation failed: ${error.toString()}',
    };
  }

  Future<void> _connect() async {
    if (!_canConnect) return;

    setState(() {
      _viewState = _ViewState.connecting;
      _errorMessage = null;
    });

    try {
      await doSomethingWithSpinner(
        context,
        _doConnect(),
      );

      // Navigate AFTER spinner completes to avoid orphaned dialog
      if (!mounted) return;
      context.goNamed(RouteNamed.uspDashboard);
    } catch (e) {
      logger.e('[RA] Connection failed: $e');
      if (!mounted) return;
      setState(() {
        _viewState = _ViewState.validated;
        _errorMessage = 'Connection failed: ${e.toString()}';
      });
    }
  }

  Future<void> _doConnect() async {
    final config = RemoteAssistanceConfig(
      guardianBaseUrl: cloudEnvironmentConfig[kCloudBase] as String,
      sessionId: widget.sessionId,
      temporaryAccessToken: widget.token,
      clientTypeId: kClientTypeId,
    );

    await ref.read(remoteAssistanceProvider.notifier).activate(config);

    // Update remote access state with session info for UI restrictions
    ref.read(remoteAccessProvider.notifier).updateSessionInfo(
          _sessionInfo,
          _remainingSeconds,
          sessionToken: widget.token,
        );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final remaining = _remainingSeconds;
      if (remaining == null || remaining <= 0) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _viewState = _ViewState.error;
          _errorMessage = 'Session has expired';
        });
        return;
      }

      setState(() => _remainingSeconds = remaining - 1);
    });
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

  String _statusToText(GRASessionStatus status) {
    return switch (status) {
      GRASessionStatus.active => 'Active',
      GRASessionStatus.pending => 'Pending',
      GRASessionStatus.initiate => 'Initiating',
      GRASessionStatus.invalid => 'Invalid',
    };
  }

  Widget _buildSessionStatusCard(BuildContext context) {
    final sessionInfo = _sessionInfo!;
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
                        _statusToText(sessionInfo.status),
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
                if (_remainingSeconds != null && _remainingSeconds! > 0) ...[
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
                        _formatDuration(_remainingSeconds!),
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
          child: AppCard(
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
                if (_viewState == _ViewState.validating) ...[
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
                if (_errorMessage != null) ...[
                  AppGap.lg(),
                  Container(
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
                            _errorMessage!,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
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
                if (_sessionInfo != null &&
                    _sessionInfo!.modelNumber.isNotEmpty) ...[
                  AppGap.lg(),
                  _buildSessionStatusCard(context),
                ],
                if (_canConnect) ...[
                  AppGap.xxxl(),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: _viewState == _ViewState.connecting
                          ? 'Connecting...'
                          : 'Connect',
                      variant: SurfaceVariant.highlight,
                      size: AppButtonSize.small,
                      onTap:
                          _viewState == _ViewState.connecting ? null : _connect,
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
