import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/model/guidan_remote_assistance.dart';

class RemoteAssistanceWidget extends ConsumerStatefulWidget {
  final Widget child;
  const RemoteAssistanceWidget({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<RemoteAssistanceWidget> createState() =>
      _RemoteAssistanceWidgetState();
}

class _RemoteAssistanceWidgetState
    extends ConsumerState<RemoteAssistanceWidget> {
  String? _sessionId;
  bool _dialogOpen = false;
  @override
  Widget build(BuildContext context) {
    final remoteClientState = ref.watch(remoteClientProvider);
    return InkWell(
      onTap: _doRemoteAssistance,
      child: widget.child,
    );
  }

  Future<void> _doRemoteAssistance() async {
    final notifier = ref.read(remoteClientProvider.notifier);
    // Fetch sessions and pick or create a session
    await notifier.fetchSessions();
    final sessions = ref.read(remoteClientProvider).sessions;
    String sessionId;
    if (sessions.isNotEmpty) {
      sessionId = sessions.first.id;
    } else {
      // If no session, show error or handle session creation as needed
      _showSupportHintModal();
      return;
    }
    _sessionId = sessionId;
    await notifier.createPin(sessionId);
    await notifier.fetchSessionInfo(sessionId);
    _showRemoteAssistanceDialog();
  }

  void _showRemoteAssistanceDialog() {
    if (_dialogOpen) return;
    _dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _RemoteAssistanceDialog(
          sessionId: _sessionId!,
          onEndSession: _handleEndSession,
          onClose: () {
            _dialogOpen = false;
          },
        );
      },
    );
  }

  Future<void> _handleEndSession() async {
    // Implement session deletion if needed
    // For now, just close dialog and clear state
    Navigator.of(context, rootNavigator: true).pop();
    _dialogOpen = false;
    // Optionally, implement session deletion in remoteClientProvider
  }

  _showSupportHintModal() {
    showSimpleAppOkDialog(context,
        title: 'Remote assistance',
        content: AppStyledText.link(
            'To take advantage of Remote Assistance, you must first contact a phone support agent. Go to <a href="http://www.linksys.com/support" target="_blank">linksys.com/support</a> and click on Phone Call to get started.',
            color: Theme.of(context).colorScheme.primary,
            defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
            tags: const [
              'a'
            ],
            callbackTags: {
              'a': (tag, data) {
                final url = data['href'];
                if (url != null) {
                  launchUrl(Uri.parse(url));
                }
              }
            }));
  }
}

class _RemoteAssistanceDialog extends ConsumerStatefulWidget {
  final String sessionId;
  final VoidCallback onEndSession;
  final VoidCallback onClose;
  const _RemoteAssistanceDialog({
    required this.sessionId,
    required this.onEndSession,
    required this.onClose,
  });
  @override
  ConsumerState<_RemoteAssistanceDialog> createState() =>
      _RemoteAssistanceDialogState();
}

class _RemoteAssistanceDialogState
    extends ConsumerState<_RemoteAssistanceDialog> {
  late final ValueNotifier<int> _timerNotifier;
  @override
  void initState() {
    super.initState();
    _timerNotifier = ValueNotifier<int>(0);
    _startPolling();
  }

  void _startPolling() async {
    final notifier = ref.read(remoteClientProvider.notifier);
    while (mounted) {
      await notifier.fetchSessionInfo(widget.sessionId);
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remoteClientProvider);
    final info = state.sessionInfo;
    final pin = state.pin ?? '';
    if (info == null) {
      return Center(child: CircularProgressIndicator());
    }
    if (info.status == GRASessionStatus.active) {
      final countingFromInfo = 1800 + (info.expiredIn);
      return _buildCountingWidget(
          DateFormatUtils.formatTimeMSS(countingFromInfo));
    } else if (info.status == GRASessionStatus.invalid) {
      return _buildErrorWidget('Invalid Session!');
    } else {
      return _buildShowPinWidget(pin);
    }
  }

  Widget _buildCountingWidget(String counting) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.labelLarge(
            'A Linksys support agent has remote access to your Linksys Smart Wi-Fi account and your home network.'),
        AppText.labelLarge(counting),
        const AppGap.medium(),
        AppFilledButton(
          'End Session',
          onTap: widget.onEndSession,
        )
      ],
    );
  }

  Widget _buildShowPinWidget(String pin) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.bodyMedium(
            'Share the PIN below with the Linksys support agent on the phone to authorize remote assistance.'),
        const AppGap.small2(),
        const AppText.bodyMedium('PIN:'),
        Center(
          child: AppText.displayMedium(
            pin,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const AppGap.medium(),
        ExpansionTile(
          title: AppText.bodyMedium(
            'Terms of service',
            color: Theme.of(context).colorScheme.primary,
          ),
          tilePadding: EdgeInsets.only(),
          children: [
            AppBulletList(children: [
              AppText.bodyMedium(
                  'You may end remote assistance at any time by clicking the orange End Session button on your screen.'),
              AppText.bodyMedium(
                  'Only the support agent to who whom you provided the PIN will have access to your Linksys Smart Wi-Fi account and home network.'),
              AppText.bodyMedium(
                  'The support agent will be able to view your home network and troubleshoot any support issues.'),
              AppText.bodyMedium(
                  'Your remote assistance session is open only until you end it. No one will have access to your Linksys Smart Wi-Fi account or home network after you end the session.'),
              AppText.bodyMedium(
                  'The support agent should never ask for your password.'),
            ]),
            const AppGap.medium(),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.labelLarge('Error - $errorMessage'),
        AppFilledButton(
          'End Session',
          onTap: widget.onEndSession,
        )
      ],
    );
  }

  @override
  void dispose() {
    widget.onClose();
    super.dispose();
  }
}
