import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/remote_assistance/services/remote_assistance_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Floating draggable chip that displays Remote Assistance session status.
///
/// Features:
/// - Draggable with auto snap-to-edge
/// - Shows remaining time with color-coded urgency
/// - Tap to show popup with session details and disconnect button
class RemoteSessionChip extends ConsumerStatefulWidget {
  const RemoteSessionChip({super.key});

  @override
  ConsumerState<RemoteSessionChip> createState() => _RemoteSessionChipState();
}

class _RemoteSessionChipState extends ConsumerState<RemoteSessionChip> {
  // Position state
  double _top = 80;
  double _left = double.infinity; // Start on right edge
  bool _isOnRightEdge = true;

  // Drag state
  Offset? _dragOffset;

  // Popup state
  final _popupKey = GlobalKey();
  OverlayEntry? _popupEntry;

  static const double _edgePadding = 16;
  static const double _chipHeight = 40;
  static const double _chipWidth = 90;

  @override
  void dispose() {
    _removePopup();
    super.dispose();
  }

  void _removePopup() {
    _popupEntry?.remove();
    _popupEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remoteAccessProvider);

    // Only show in remote mode with valid session
    if (!GlobalConfig.remote.isActive || state.sessionInfo == null) {
      return const SizedBox.shrink();
    }

    // Listen for session becoming invalid (e.g., 401 from polling)
    // and auto-disconnect
    ref.listen(remoteAccessProvider, (prev, next) {
      final prevStatus = prev?.sessionInfo?.status;
      final nextStatus = next.sessionInfo?.status;

      // Only trigger if status changed TO invalid (not initial invalid)
      if (prevStatus != null &&
          prevStatus != GRASessionStatus.invalid &&
          nextStatus == GRASessionStatus.invalid) {
        _handleForceDisconnect(context, ref);
      }
    });

    final remainingSeconds = state.remainingSeconds ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    final urgencyColor = _getUrgencyColor(remainingSeconds, colorScheme);
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;

    // Calculate actual left position
    final actualLeft =
        _isOnRightEdge ? screenSize.width - _chipWidth - _edgePadding : _left;

    return Positioned(
      top: _top.clamp(safeArea.top + _edgePadding,
          screenSize.height - _chipHeight - safeArea.bottom - _edgePadding),
      left: actualLeft.clamp(
          _edgePadding, screenSize.width - _chipWidth - _edgePadding),
      child: GestureDetector(
        onPanStart: (details) {
          _removePopup();
          _dragOffset = details.localPosition;
        },
        onPanUpdate: (details) {
          setState(() {
            _top = details.globalPosition.dy - (_dragOffset?.dy ?? 0);
            _left = details.globalPosition.dx - (_dragOffset?.dx ?? 0);
            _isOnRightEdge = false;
          });
        },
        onPanEnd: (details) {
          // Snap to nearest edge
          final centerX = _left + _chipWidth / 2;
          final screenCenter = screenSize.width / 2;

          setState(() {
            if (centerX > screenCenter) {
              // Snap to right
              _isOnRightEdge = true;
              _left = screenSize.width - _chipWidth - _edgePadding;
            } else {
              // Snap to left
              _isOnRightEdge = false;
              _left = _edgePadding;
            }
          });
        },
        onTap: () => _showPopup(context, ref, state),
        child: AppSurface(
          key: _popupKey,
          variant: SurfaceVariant.elevated,
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.support_agent,
                size: 18,
                color: urgencyColor,
              ),
              const SizedBox(width: 6),
              AppText.labelMedium(
                _formatTime(remainingSeconds),
                color: urgencyColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns urgency color based on remaining time:
  /// - error: <= 1 minute
  /// - tertiary: <= 5 minutes
  /// - primary: normal
  Color _getUrgencyColor(int seconds, ColorScheme colorScheme) {
    if (seconds <= 60) {
      return colorScheme.error;
    } else if (seconds <= 300) {
      return colorScheme.tertiary;
    }
    return colorScheme.primary;
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '0:00';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  void _showPopup(
      BuildContext context, WidgetRef ref, RemoteAccessState state) {
    _removePopup();

    final renderBox =
        _popupKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final chipPosition = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // Determine popup position (show on opposite side of chip)
    final showOnLeft = chipPosition.dx > screenSize.width / 2;
    const popupWidth = 280.0;

    final popupLeft = showOnLeft
        ? chipPosition.dx - popupWidth - 8
        : chipPosition.dx + _chipWidth + 8;

    _popupEntry = OverlayEntry(
      builder: (context) => _SessionPopup(
        left: popupLeft.clamp(16, screenSize.width - popupWidth - 16),
        top: chipPosition.dy,
        width: popupWidth,
        state: state,
        onClose: _removePopup,
        onDisconnect: () => _disconnect(context, ref),
      ),
    );

    Overlay.of(context).insert(_popupEntry!);
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    _removePopup();

    // Capture all refs BEFORE async gap — context/ref may become invalid after await
    final router = GoRouter.of(context);
    final state = ref.read(remoteAccessProvider);
    final notifier = ref.read(remoteAccessProvider.notifier);
    final authNotifier = ref.read(authProvider.notifier);
    final service = ref.read(remoteAssistanceServiceProvider);

    final sessionId = state.sessionInfo?.id;
    final sessionToken = state.sessionToken;

    // Call API to end session (best effort — don't block on failure)
    if (sessionId != null && sessionToken != null) {
      try {
        await service.endSessionForCA(
          sessionToken: sessionToken,
          sessionId: sessionId,
        );
        logger.d('[RA] Session ended via API');
      } catch (e) {
        logger.w('[RA] Failed to end session via API: $e');
      }
    }

    // Clear session state (triggers chip to disappear)
    notifier.clearSession();

    // Navigate using captured router, then logout after frame completes
    router.go('${RoutePath.remoteAssistanceConfirm}?ended=true');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authNotifier.logout();
    });
  }

  /// Handle force disconnect when session becomes invalid (e.g., 401).
  ///
  /// Unlike manual disconnect, we don't call the API (it already failed)
  /// and we use a different query param to show appropriate message.
  void _handleForceDisconnect(BuildContext context, WidgetRef ref) {
    _removePopup();

    final router = GoRouter.of(context);
    final notifier = ref.read(remoteAccessProvider.notifier);
    final authNotifier = ref.read(authProvider.notifier);

    logger.d('[RA] Force disconnect due to session invalidation');

    // Clear session state
    notifier.clearSession();

    // Navigate with expired param (different message than manual end)
    router.go('${RoutePath.remoteAssistanceConfirm}?expired=true');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authNotifier.logout();
    });
  }
}

/// Popup overlay showing session details
class _SessionPopup extends StatelessWidget {
  final double left;
  final double top;
  final double width;
  final RemoteAccessState state;
  final VoidCallback onClose;
  final VoidCallback onDisconnect;

  const _SessionPopup({
    required this.left,
    required this.top,
    required this.width,
    required this.state,
    required this.onClose,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final sessionInfo = state.sessionInfo!;
    final expiryTime = state.expiryTime;
    final colorScheme = Theme.of(context).colorScheme;

    final iconName =
        routerIconTestByModel(modelNumber: sessionInfo.modelNumber);
    final routerImage = DeviceImageHelper.getRouterImage(iconName);

    return Stack(
      children: [
        // Backdrop to close popup
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Popup content
        Positioned(
          left: left,
          top: top,
          width: width,
          child: AppSurface(
            borderRadius: 12,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.support_agent,
                          color: colorScheme.primary, size: 20),
                      AppGap.sm(),
                      Expanded(
                        child: AppText.titleSmall('Remote Assistance'),
                      ),
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(12),
                        child: Icon(Icons.close,
                            size: 20,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                  AppGap.md(),

                  // Router info
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(image: routerImage, fit: BoxFit.contain),
                        ),
                      ),
                      AppGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.bodyMedium(sessionInfo.modelNumber),
                            AppText.bodySmall(
                              sessionInfo.serialNumber,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppGap.md(),

                  // Status row
                  _buildInfoRow(
                    'Status',
                    _buildStatusBadge(sessionInfo.status, colorScheme),
                    colorScheme,
                  ),
                  AppGap.sm(),

                  // Expiry time row (fixed time, doesn't change)
                  _buildInfoRow(
                    'Expires At',
                    AppText.labelMedium(
                      _formatExpiryTime(expiryTime),
                      color: colorScheme.onSurface,
                    ),
                    colorScheme,
                  ),
                  AppGap.lg(),

                  // Disconnect button
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.dangerOutline(
                      label: 'End Session',
                      size: AppButtonSize.small,
                      onTap: onDisconnect,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, Widget value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.bodySmall(label,
            color: colorScheme.onSurface.withValues(alpha: 0.6)),
        value,
      ],
    );
  }

  Widget _buildStatusBadge(GRASessionStatus status, ColorScheme colorScheme) {
    final color = switch (status) {
      GRASessionStatus.active => colorScheme.primary,
      GRASessionStatus.pending => colorScheme.tertiary,
      GRASessionStatus.initiate => colorScheme.secondary,
      GRASessionStatus.invalid => colorScheme.error,
    };

    final text = switch (status) {
      GRASessionStatus.active => 'Active',
      GRASessionStatus.pending => 'Pending',
      GRASessionStatus.initiate => 'Initiating',
      GRASessionStatus.invalid => 'Invalid',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 4),
          AppText.labelSmall(text, color: color),
        ],
      ),
    );
  }

  String _formatExpiryTime(DateTime? expiryTime) {
    if (expiryTime == null) return 'Unknown';
    if (expiryTime.isBefore(DateTime.now())) return 'Expired';

    final hour = expiryTime.hour;
    final minute = expiryTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$hour12:$minute $period';
  }
}
