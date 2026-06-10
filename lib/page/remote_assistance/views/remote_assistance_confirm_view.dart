import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/cloud_const.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class RemoteAssistanceConfirmView extends ConsumerStatefulWidget {
  final String sessionId;

  const RemoteAssistanceConfirmView({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<RemoteAssistanceConfirmView> createState() =>
      _RemoteAssistanceConfirmViewState();
}

class _RemoteAssistanceConfirmViewState
    extends ConsumerState<RemoteAssistanceConfirmView> {
  final _tokenController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Please enter the access token');
      return;
    }

    setState(() => _errorMessage = null);

    try {
      await doSomethingWithSpinner(
        context,
        _doConnect(token),
      );
    } catch (e) {
      logger.e('[RA] Connection failed: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection failed: ${e.toString()}';
      });
    }
  }

  Future<void> _doConnect(String token) async {
    final config = RemoteAssistanceConfig(
      guardianBaseUrl: cloudEnvironmentConfig[kCloudBase] as String,
      sessionId: widget.sessionId,
      temporaryAccessToken: token,
      clientTypeId: kClientTypeId,
    );

    await ref.read(remoteAssistanceProvider.notifier).activate(config);

    if (!mounted) return;
    context.goNamed(RouteNamed.uspDashboard);
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                AppGap.md(),
                AppText.bodyMedium(
                  'Environment: ${cloudEnvironmentConfig[kCloudBase]}',
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
                AppGap.xxxl(),
                AppPasswordInput(
                  controller: _tokenController,
                  hintText: 'Temporary Access Token',
                  errorText: _errorMessage,
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  onSubmitted: (_) => _connect(),
                ),
                AppGap.xxxl(),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Connect',
                    variant: SurfaceVariant.highlight,
                    size: AppButtonSize.small,
                    onTap: _connect,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
