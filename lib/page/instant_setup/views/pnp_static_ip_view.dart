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

/// Static IP configuration form.
class PnpStaticIpView extends ConsumerStatefulWidget {
  const PnpStaticIpView({super.key});

  @override
  ConsumerState<PnpStaticIpView> createState() => _PnpStaticIpViewState();
}

class _PnpStaticIpViewState extends ConsumerState<PnpStaticIpView> {
  final _ipController = TextEditingController();
  final _subnetController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _dns1Controller = TextEditingController();
  final _dns2Controller = TextEditingController();
  bool _showDns = false;

  @override
  void initState() {
    super.initState();
    _prefillFromCurrentSettings();
  }

  void _prefillFromCurrentSettings() {
    final phase = ref.read(pnpProvider).phase;
    if (phase is NoInternet && phase.currentWanSettings != null) {
      final wan = phase.currentWanSettings!;
      _ipController.text = wan.staticIpAddress;
      _subnetController.text = wan.subnetMask;
      _gatewayController.text = wan.defaultGateway;
      _dns1Controller.text = wan.dnsServer1;
      _dns2Controller.text = wan.dnsServer2;
      if (wan.dnsServer1.isNotEmpty || wan.dnsServer2.isNotEmpty) {
        _showDns = true;
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
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
    final canSave = _ipController.text.isNotEmpty &&
        _subnetController.text.isNotEmpty &&
        _gatewayController.text.isNotEmpty;

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
        AppText.bodyMedium(loc(context).pnpStaticIpDesc),
        AppGap.xl(),
        AppIpv4TextField(
          label: loc(context).ipAddress,
          controller: _ipController,
          onChanged: (_) => setState(() {}),
        ),
        AppGap.lg(),
        AppIpv4TextField(
          label: loc(context).subnetMask,
          controller: _subnetController,
          onChanged: (_) => setState(() {}),
        ),
        AppGap.lg(),
        AppIpv4TextField(
          label: loc(context).defaultGateway,
          controller: _gatewayController,
          onChanged: (_) => setState(() {}),
        ),
        AppGap.xl(),
        InkWell(
          onTap: () => setState(() => _showDns = !_showDns),
          child: Row(
            children: [
              AppIcon.font(
                _showDns
                    ? Icons.remove_circle_outline
                    : Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              AppGap.sm(),
              AppText.bodyMedium(loc(context).dns),
            ],
          ),
        ),
        if (_showDns) ...[
          AppGap.lg(),
          AppIpv4TextField(
            label: '${loc(context).dns} 1',
            controller: _dns1Controller,
          ),
          AppGap.lg(),
          AppIpv4TextField(
            label: '${loc(context).dns} 2',
            controller: _dns2Controller,
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
    final config = PnpIspConfig(
      type: IspConnectionType.staticIp,
      staticIpAddress: _ipController.text,
      subnetMask: _subnetController.text,
      defaultGateway: _gatewayController.text,
      dnsServer1: _dns1Controller.text,
      dnsServer2: _dns2Controller.text,
    );
    ref.read(pnpProvider.notifier).saveIspWithProgress(config);
  }
}
