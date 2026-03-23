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

/// ISP type selection + PPPoE / Static IP configuration forms.
class PnpIspSettingsView extends ConsumerStatefulWidget {
  final IspConnectionType? initialType;

  const PnpIspSettingsView({super.key, this.initialType});

  @override
  ConsumerState<PnpIspSettingsView> createState() => _PnpIspSettingsViewState();
}

class _PnpIspSettingsViewState extends ConsumerState<PnpIspSettingsView> {
  late IspConnectionType _selectedType;
  final _pppUsernameController = TextEditingController();
  final _pppPasswordController = TextEditingController();
  final _pppServiceController = TextEditingController();
  final _staticIpController = TextEditingController();
  final _subnetController = TextEditingController();
  final _gatewayController = TextEditingController();
  final _dns1Controller = TextEditingController();
  final _dns2Controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? IspConnectionType.dhcp;
  }

  @override
  void dispose() {
    _pppUsernameController.dispose();
    _pppPasswordController.dispose();
    _pppServiceController.dispose();
    _staticIpController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for internet recovery
    ref.listen(pnpProvider, (prev, next) {
      if (next.phase is WizardConfiguring || next.phase is WizardInitializing) {
        context.go(RoutePath.pnp);
      }
      if (next.phase is NoInternet) {
        setState(() => _saving = false);
      }
    });

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: loc(context).pnpIspTypeSelectionTitle,
      scrollable: true,
      onBackTap: () => context.pop(),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: _saving ? _buildSaving(context) : _buildForm(context),
      ),
    );
  }

  Widget _buildSaving(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          AppGap.lg(),
          AppText.bodyMedium(loc(context).pnpSavingChangesDesc),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ISP type selection
        AppText.titleMedium(loc(context).pnpIspTypeSelectionTitle),
        AppGap.lg(),
        _buildTypeOption(
          context,
          IspConnectionType.dhcp,
          'DHCP',
          loc(context).pnpIspTypeSelectionDhcpDesc,
        ),
        _buildTypeOption(
          context,
          IspConnectionType.pppoe,
          'PPPoE',
          loc(context).pnpIspTypeSelectionPppoeDesc,
        ),
        _buildTypeOption(
          context,
          IspConnectionType.staticIp,
          loc(context).ipAddress,
          loc(context).pnpIspTypeSelectionStaticDesc,
        ),
        AppGap.xl(),

        // Type-specific form fields
        if (_selectedType == IspConnectionType.pppoe) _buildPppoeForm(context),
        if (_selectedType == IspConnectionType.staticIp)
          _buildStaticIpForm(context),

        AppGap.xxxl(),

        // Save button
        AppButton(
          label: loc(context).save,
          onTap: _onSave,
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    BuildContext context,
    IspConnectionType type,
    String title,
    String description,
  ) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            AppGap.md(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleSmall(title),
                  AppGap.xs(),
                  AppText.bodySmall(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPppoeForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(loc(context).pnpPppoeTitle),
        AppGap.lg(),
        AppText.labelMedium(loc(context).username),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).username,
          controller: _pppUsernameController,
        ),
        AppGap.md(),
        AppText.labelMedium(loc(context).password),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).password,
          controller: _pppPasswordController,
          obscureText: true,
        ),
        AppGap.md(),
        AppText.labelMedium(loc(context).pnpPppoeDesc),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).pnpPppoeTitle,
          controller: _pppServiceController,
        ),
      ],
    );
  }

  Widget _buildStaticIpForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(loc(context).pnpStaticIpDesc),
        AppGap.lg(),
        AppText.labelMedium(loc(context).ipAddress),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).ipAddress,
          controller: _staticIpController,
        ),
        AppGap.md(),
        AppText.labelMedium(loc(context).subnetMask),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).subnetMask,
          controller: _subnetController,
        ),
        AppGap.md(),
        AppText.labelMedium(loc(context).defaultGateway),
        AppGap.xs(),
        AppTextField(
          hintText: loc(context).defaultGateway,
          controller: _gatewayController,
        ),
        AppGap.md(),
        AppText.labelMedium('${loc(context).dns} 1'),
        AppGap.xs(),
        AppTextField(
          hintText: '${loc(context).dns} 1',
          controller: _dns1Controller,
        ),
        AppGap.md(),
        AppText.labelMedium('${loc(context).dns} 2'),
        AppGap.xs(),
        AppTextField(
          hintText: '${loc(context).dns} 2',
          controller: _dns2Controller,
        ),
      ],
    );
  }

  void _onSave() {
    setState(() => _saving = true);

    final config = PnpIspConfig(
      type: _selectedType,
      pppUsername: _pppUsernameController.text,
      pppPassword: _pppPasswordController.text,
      pppoeServiceName: _pppServiceController.text,
      staticIpAddress: _staticIpController.text,
      subnetMask: _subnetController.text,
      defaultGateway: _gatewayController.text,
      dnsServer1: _dns1Controller.text,
      dnsServer2: _dns2Controller.text,
    );

    ref.read(pnpProvider.notifier).saveIspSettingsAndCheck(config);
  }
}
