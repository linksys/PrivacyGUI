import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_isp_saving_progress.dart';
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
  final _vlanIdController = TextEditingController();
  bool _showVlan = false;

  @override
  void initState() {
    super.initState();
    _prefillFromCurrentSettings();
  }

  void _prefillFromCurrentSettings() {
    final phase = ref.read(pnpProvider).phase;
    if (phase is NoInternet && phase.currentWanSettings != null) {
      final wan = phase.currentWanSettings!;
      _usernameController.text = wan.pppUsername;
      _passwordController.text = wan.pppPassword;
      if (wan.vlanEnabled) {
        _showVlan = true;
        _vlanIdController.text = wan.vlanId.toString();
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _vlanIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for internet recovery, save success, or save failure.
    ref.listen(pnpProvider, (prev, next) {
      if (next.phase is WizardConfiguring || next.phase is WizardInitializing) {
        context.go(RoutePath.pnp);
      } else if (prev?.phase is IspSaving &&
          next.phase is NoInternet &&
          next.errorMessage != null) {
        showFailedSnackBar(context, next.errorMessage!);
      }
    });

    final phase = ref.watch(pnpProvider).phase;
    final canSave = _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;

    if (phase is IspSaving) {
      return UiKitPageView(
        scrollable: false,
        appBarStyle: UiKitAppBarStyle.none,
        useMainPadding: false,
        child: (context, constraints) => PnpIspSavingProgress(phase: phase),
      );
    }

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      onBackTap: () => context.pop(),
      child: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildForm(context, canSave),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool canSave) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.bodyMedium(loc(context).pnpIspSettingsContactDesc),
        AppGap.xl(),
        AppText.labelMedium(loc(context).username),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).username,
          controller: _usernameController,
          onChanged: (_) => setState(() {}),
        ),
        AppGap.lg(),
        AppPasswordInput(
          label: loc(context).password,
          hintText: loc(context).password,
          controller: _passwordController,
          onChanged: (_) => setState(() {}),
        ),
        AppGap.xl(),
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
        AppGap.xxxl(),
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton.primary(
            label: loc(context).save,
            onTap: canSave ? _onSave : null,
          ),
        ),
      ],
    );
  }

  void _onSave() {
    final vlanId = int.tryParse(_vlanIdController.text) ?? 0;
    final config = PnpIspConfig(
      type: _showVlan ? IspConnectionType.pppoeVlan : IspConnectionType.pppoe,
      pppUsername: _usernameController.text,
      pppPassword: _passwordController.text,
      vlanEnabled: _showVlan,
      vlanId: vlanId,
    );
    ref.read(pnpProvider.notifier).saveIspWithProgress(config);
  }
}
