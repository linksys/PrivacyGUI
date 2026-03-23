import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// PPPoE configuration form (with optional VLAN ID toggle).
class PnpPppoeView extends ConsumerStatefulWidget {
  const PnpPppoeView({super.key});

  @override
  ConsumerState<PnpPppoeView> createState() => _PnpPppoeViewState();
}

class _PnpPppoeViewState extends ConsumerState<PnpPppoeView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serviceController = TextEditingController();
  final _vlanIdController = TextEditingController();
  bool _showVlan = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serviceController.dispose();
    _vlanIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for internet recovery
    ref.listen(pnpProvider, (prev, next) {
      if (next.phase is WizardConfiguring || next.phase is WizardInitializing) {
        context.go(RoutePath.pnp);
      }
    });

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: loc(context).pnpPppoeTitle,
      scrollable: true,
      onBackTap: () => context.pop(),
      bottomBar: UiKitBottomBarConfig(
        positiveLabel: loc(context).save,
        onPositiveTap: _onSave,
      ),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText.bodyMedium(loc(context).pnpPppoeDesc),
            AppGap.xl(),

            // Username
            AppText.labelMedium(loc(context).username),
            AppGap.xs(),
            AppTextField(
              hintText: loc(context).username,
              controller: _usernameController,
            ),
            AppGap.lg(),

            // Password
            AppPasswordInput(
              label: loc(context).password,
              hintText: loc(context).password,
              controller: _passwordController,
            ),
            AppGap.lg(),

            // Service name (optional)
            AppText.labelMedium(loc(context).pnpPppoeTitle),
            AppGap.xs(),
            AppTextField(
              hintText: loc(context).pnpPppoeTitle,
              controller: _serviceController,
            ),
            AppGap.xl(),

            // VLAN toggle
            InkWell(
              onTap: () => setState(() => _showVlan = !_showVlan),
              child: Row(
                children: [
                  AppIcon.font(
                    _showVlan
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  AppGap.sm(),
                  AppText.bodyMedium(
                    _showVlan
                        ? loc(context).pnpPppoeRemoveVlan
                        : loc(context).pnpPppoeAddVlan,
                  ),
                ],
              ),
            ),

            if (_showVlan) ...[
              AppGap.lg(),
              AppText.labelMedium('VLAN ID'),
              AppGap.xs(),
              AppTextField(
                hintText: 'VLAN ID',
                controller: _vlanIdController,
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onSave() {
    final vlanId = int.tryParse(_vlanIdController.text) ?? 0;
    final config = PnpIspConfig(
      type: _showVlan ? IspConnectionType.pppoeVlan : IspConnectionType.pppoe,
      pppUsername: _usernameController.text,
      pppPassword: _passwordController.text,
      pppoeServiceName: _serviceController.text,
      vlanEnabled: _showVlan,
      vlanId: vlanId,
    );
    ref.read(pnpProvider.notifier).saveIspWithProgress(config);
  }
}
