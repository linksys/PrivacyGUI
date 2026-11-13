import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_phase.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/internet_troubleshooting_provider.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_isp_saving_progress.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
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

  /// Prefill from the router's WAN once it has been read — which the hub started
  /// when it opened, so it is normally here already. Once only: a read that
  /// lands later (after a save, say) must not overwrite what the user typed.
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(troubleshootingWanPrefillProvider, (_, next) {
      final wan = next.valueOrNull;
      if (wan != null && !_prefilled) setState(() => _prefill(wan));
    });
    final wan = ref.read(troubleshootingWanPrefillProvider).valueOrNull;
    if (wan != null) _prefill(wan);
  }

  void _prefill(UspInternetSettingsForm wan) {
    _prefilled = true;
    _ipController.text = wan.staticIpAddress;
    _subnetController.text = wan.subnetMask;
    _gatewayController.text = wan.defaultGateway;
    _dns1Controller.text = wan.dnsServer1;
    _dns2Controller.text = wan.dnsServer2;
    if (wan.dnsServer1.isNotEmpty || wan.dnsServer2.isNotEmpty) {
      _showDns = true;
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
    // A failed save, said once. A save that brings the internet back, or ends on
    // a router that cannot be read, is handed over by the hub underneath this
    // page (#1511 P1).
    ref.listen(internetTroubleshootingProvider, (prev, next) {
      if (prev is IspSaving &&
          next is TroubleshootingNoInternet &&
          next.saveError != null) {
        showFailedSnackBar(
            context, localizeServiceError(context, next.saveError!));
      }
    });

    final phase = ref.watch(internetTroubleshootingProvider);
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
    ref
        .read(internetTroubleshootingProvider.notifier)
        .saveIspWithProgress(config);
  }
}
