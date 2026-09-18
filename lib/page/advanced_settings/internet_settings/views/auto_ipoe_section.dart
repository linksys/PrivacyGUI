import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class AutoIPoESection extends StatefulWidget {
  const AutoIPoESection({
    super.key,
    required this.settings,
    required this.status,
    required this.capabilities,
    required this.isEditing,
    required this.onChanged,
    this.highlightedFieldGroup = AutoIPoEFieldGroup.none,
  });

  final AutoIPoESettings settings;
  final AutoIPoEStatus status;
  final AutoIPoECapabilities capabilities;
  final bool isEditing;
  final ValueChanged<AutoIPoESettings> onChanged;
  final AutoIPoEFieldGroup highlightedFieldGroup;

  @override
  State<AutoIPoESection> createState() => _AutoIPoESectionState();
}

class _AutoIPoESectionState extends State<AutoIPoESection> {
  static const _inputPadding = EdgeInsets.symmetric(vertical: Spacing.small2);

  final _standardIpv6RemoteController = TextEditingController();
  final _standardIpv6InterfaceIdController = TextEditingController();
  final _standardIpv4AddressController = TextEditingController();

  final _biglobeUserIdController = TextEditingController();
  final _biglobePasswordController = TextEditingController();

  final _v6PlusIpv6RemoteController = TextEditingController();
  final _v6PlusIpv6InterfaceIdController = TextEditingController();
  final _v6PlusIpv4AddressController = TextEditingController();
  final _v6PlusUserIdController = TextEditingController();
  final _v6PlusPasswordController = TextEditingController();

  final _transixIpv6RemoteController = TextEditingController();
  final _transixIpv6InterfaceIdController = TextEditingController();
  final _transixIpv4AddressController = TextEditingController();
  final _transixUpdateUserIdController = TextEditingController();
  final _transixUpdatePasswordController = TextEditingController();

  final _asahiAuthKeyController = TextEditingController();
  final _asahiAuthPasswordController = TextEditingController();

  final _xpassFqdnController = TextEditingController();
  final _xpassDdnsIdController = TextEditingController();
  final _xpassDdnsPasswordController = TextEditingController();
  final _xpassBasicAuthIdController = TextEditingController();
  final _xpassBasicAuthPasswordController = TextEditingController();
  final _xpassUpdateUrlController = TextEditingController();
  final _xpassIpv6RemoteController = TextEditingController();
  final _xpassIpv4AddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFromSettings();
  }

  @override
  void didUpdateWidget(covariant AutoIPoESection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _syncFromSettings();
    }
  }

  @override
  void dispose() {
    _standardIpv6RemoteController.dispose();
    _standardIpv6InterfaceIdController.dispose();
    _standardIpv4AddressController.dispose();
    _biglobeUserIdController.dispose();
    _biglobePasswordController.dispose();
    _v6PlusIpv6RemoteController.dispose();
    _v6PlusIpv6InterfaceIdController.dispose();
    _v6PlusIpv4AddressController.dispose();
    _v6PlusUserIdController.dispose();
    _v6PlusPasswordController.dispose();
    _transixIpv6RemoteController.dispose();
    _transixIpv6InterfaceIdController.dispose();
    _transixIpv4AddressController.dispose();
    _transixUpdateUserIdController.dispose();
    _transixUpdatePasswordController.dispose();
    _asahiAuthKeyController.dispose();
    _asahiAuthPasswordController.dispose();
    _xpassFqdnController.dispose();
    _xpassDdnsIdController.dispose();
    _xpassDdnsPasswordController.dispose();
    _xpassBasicAuthIdController.dispose();
    _xpassBasicAuthPasswordController.dispose();
    _xpassUpdateUrlController.dispose();
    _xpassIpv6RemoteController.dispose();
    _xpassIpv4AddressController.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  void _syncFromSettings() {
    final settings = widget.settings;
    _syncController(
      _standardIpv6RemoteController,
      settings.standardIpipSettings.ipv6Remote ?? '',
    );
    _syncController(
      _standardIpv6InterfaceIdController,
      settings.standardIpipSettings.ipv6InterfaceId ?? '',
    );
    _syncController(
      _standardIpv4AddressController,
      settings.standardIpipSettings.ipv4Address ?? '',
    );

    _syncController(
      _biglobeUserIdController,
      settings.biglobeStaticIpSettings.userId.value ?? '',
    );
    _syncController(
      _biglobePasswordController,
      settings.biglobeStaticIpSettings.userPassword.value ?? '',
    );

    _syncController(
      _v6PlusIpv6RemoteController,
      settings.v6PlusStaticIpSettings.ipv6Remote ?? '',
    );
    _syncController(
      _v6PlusIpv6InterfaceIdController,
      settings.v6PlusStaticIpSettings.ipv6InterfaceId ?? '',
    );
    _syncController(
      _v6PlusIpv4AddressController,
      settings.v6PlusStaticIpSettings.ipv4Address ?? '',
    );
    _syncController(
      _v6PlusUserIdController,
      settings.v6PlusStaticIpSettings.userId ?? '',
    );
    _syncController(
      _v6PlusPasswordController,
      settings.v6PlusStaticIpSettings.userPassword.value ?? '',
    );

    _syncController(
      _transixIpv6RemoteController,
      settings.transixStaticIpSettings.ipv6Remote ?? '',
    );
    _syncController(
      _transixIpv6InterfaceIdController,
      settings.transixStaticIpSettings.ipv6InterfaceId ?? '',
    );
    _syncController(
      _transixIpv4AddressController,
      settings.transixStaticIpSettings.ipv4Address ?? '',
    );
    _syncController(
      _transixUpdateUserIdController,
      settings.transixStaticIpSettings.updateUserId ?? '',
    );
    _syncController(
      _transixUpdatePasswordController,
      settings.transixStaticIpSettings.updatePassword.value ?? '',
    );

    _syncController(
      _asahiAuthKeyController,
      settings.asahiNetStaticIpSettings.authenticationKey ?? '',
    );
    _syncController(
      _asahiAuthPasswordController,
      settings.asahiNetStaticIpSettings.authenticationPassword.value ?? '',
    );

    _syncController(
        _xpassFqdnController, settings.xpassStaticIpSettings.fqdn ?? '');
    _syncController(
      _xpassDdnsIdController,
      settings.xpassStaticIpSettings.ddnsId ?? '',
    );
    _syncController(
      _xpassDdnsPasswordController,
      settings.xpassStaticIpSettings.ddnsPassword.value ?? '',
    );
    _syncController(
      _xpassBasicAuthIdController,
      settings.xpassStaticIpSettings.basicAuthId ?? '',
    );
    _syncController(
      _xpassBasicAuthPasswordController,
      settings.xpassStaticIpSettings.basicAuthPassword.value ?? '',
    );
    _syncController(
      _xpassUpdateUrlController,
      settings.xpassStaticIpSettings.ddnsUpdateUrl ?? '',
    );
    _syncController(
      _xpassIpv6RemoteController,
      settings.xpassStaticIpSettings.ipv6Remote ?? '',
    );
    _syncController(
      _xpassIpv4AddressController,
      settings.xpassStaticIpSettings.ipv4Address ?? '',
    );
  }

  AutoIPoESecret _secretFromInput(AutoIPoESecret current, String value) {
    if (value.isEmpty) {
      return AutoIPoESecret(hasStoredValue: current.hasStoredValue);
    }
    return AutoIPoESecret(
      value: value,
      hasStoredValue: current.hasStoredValue,
    );
  }

  String _modeLabel(AutoIPoEMode mode) {
    final l = loc(context);
    return switch (mode) {
      AutoIPoEMode.auto => l.autoIpoeModeAuto,
      AutoIPoEMode.biglobeStaticIp => l.autoIpoeModeBiglobeStaticIp,
      AutoIPoEMode.standardIpip => l.autoIpoeModeStandardIpip,
      AutoIPoEMode.v6PlusStaticIp => l.autoIpoeModeV6PlusStaticIp,
      AutoIPoEMode.ocnVirtualConnectStaticIp =>
        l.autoIpoeModeOcnVirtualConnectStaticIp,
      AutoIPoEMode.transixStaticIp => l.autoIpoeModeTransixStaticIp,
      AutoIPoEMode.asahiNetStaticIp => l.autoIpoeModeAsahiNetStaticIp,
      AutoIPoEMode.xpassStaticIp => l.autoIpoeModeXpassStaticIp,
      AutoIPoEMode.ocxHikariV6ixStaticIp => l.autoIpoeModeOcxHikariV6ixStaticIp,
      AutoIPoEMode.disabled => l.autoIpoeModeDisabled,
    };
  }

  String _secretLabel(AutoIPoESecret secret) {
    return secret.hasStoredValue ? loc(context).autoIpoeConfigured : '-';
  }

  String _applyStateLabel(AutoIPoEApplyState applyState) {
    final l = loc(context);
    return switch (applyState) {
      AutoIPoEApplyState.idle => l.autoIpoeApplyStateIdle,
      AutoIPoEApplyState.applying => l.autoIpoeApplyStateApplying,
      AutoIPoEApplyState.active => l.autoIpoeApplyStateActive,
      AutoIPoEApplyState.failed => l.autoIpoeApplyStateFailed,
      AutoIPoEApplyState.resetting => l.autoIpoeApplyStateResetting,
    };
  }

  Widget _infoRow(String title, String description) {
    return AppSettingCard.noBorder(
      title: title,
      description: description,
      padding: const EdgeInsets.symmetric(vertical: Spacing.small3),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: _inputPadding,
      child: AppTextField(
        headerText: label,
        controller: controller,
        border: const OutlineInputBorder(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required bool hasStoredValue,
  }) {
    return Padding(
      padding: _inputPadding,
      child: AppPasswordField(
        headerText: label,
        hintText: hasStoredValue ? loc(context).autoIpoeStoredOnRouter : '',
        controller: controller,
        border: const OutlineInputBorder(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _biglobeCredentialField({
    required Key key,
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required bool hasStoredValue,
    required bool obscureText,
  }) {
    return Padding(
      padding: _inputPadding,
      child: AppTextField(
        key: key,
        headerText: label,
        hintText: hasStoredValue ? loc(context).autoIpoeStoredOnRouter : '',
        controller: controller,
        secured: obscureText,
        border: const OutlineInputBorder(),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
          LengthLimitingTextInputFormatter(32),
        ],
        onChanged: onChanged,
      ),
    );
  }

  List<AutoIPoEMode> get _editableModes {
    final supported = widget.capabilities.supportedModes
        .where((mode) => mode != AutoIPoEMode.disabled)
        .toList();
    if (supported.isNotEmpty) {
      return supported;
    }
    return const [AutoIPoEMode.auto];
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEditing ? _buildEditing() : _buildInfo();
  }

  Widget _buildInfo() {
    final selectedMode = widget.settings.selectedMode == AutoIPoEMode.disabled
        ? AutoIPoEMode.auto
        : widget.settings.selectedMode;
    final currentVne = widget.status.currentVNE?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoRow(loc(context).autoIpoeMode, _modeLabel(selectedMode)),
        _infoRow(
          loc(context).autoIpoeApplyState,
          _applyStateLabel(widget.status.applyState),
        ),
        if (currentVne != null && currentVne.isNotEmpty)
          _infoRow(loc(context).autoIpoeCurrentVne, currentVne),
        if (widget.status.blockIPv6ManualConfiguration)
          _infoRow(
            loc(context).autoIpoeIpv6Controls,
            loc(context).autoIpoeManagedBy,
          ),
        ..._buildModeInfo(selectedMode),
      ],
    );
  }

  List<Widget> _buildModeInfo(AutoIPoEMode mode) {
    final settings = widget.settings;
    return switch (mode) {
      AutoIPoEMode.auto => [
          _infoRow(
            loc(context).autoIpoeDetails,
            loc(context).autoIpoeNoAdditionalParameters,
          ),
        ],
      AutoIPoEMode.biglobeStaticIp => [
          _infoRow(
            loc(context).autoIpoeUserId,
            _secretLabel(settings.biglobeStaticIpSettings.userId),
          ),
          _infoRow(
            loc(context).password,
            _secretLabel(settings.biglobeStaticIpSettings.userPassword),
          ),
        ],
      AutoIPoEMode.standardIpip => [
          _infoRow(
            loc(context).autoIpoeIpv6Remote,
            settings.standardIpipSettings.ipv6Remote ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeInterfaceId,
            settings.standardIpipSettings.ipv6InterfaceId ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeIpv4Address,
            settings.standardIpipSettings.ipv4Address ?? '-',
          ),
        ],
      AutoIPoEMode.v6PlusStaticIp => [
          _infoRow(
            loc(context).autoIpoeBrIpv6Address,
            settings.v6PlusStaticIpSettings.ipv6Remote ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeInterfaceId,
            settings.v6PlusStaticIpSettings.ipv6InterfaceId ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeIpv4GlobalAddress,
            settings.v6PlusStaticIpSettings.ipv4Address ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeUserId,
            settings.v6PlusStaticIpSettings.userId ?? '-',
          ),
          _infoRow(
            loc(context).password,
            _secretLabel(settings.v6PlusStaticIpSettings.userPassword),
          ),
        ],
      AutoIPoEMode.ocnVirtualConnectStaticIp => [
          _infoRow(
            loc(context).autoIpoeDetails,
            loc(context).autoIpoeNoAdditionalParameters,
          ),
        ],
      AutoIPoEMode.transixStaticIp => [
          _infoRow(
            loc(context).autoIpoeIpv6TunnelBr,
            settings.transixStaticIpSettings.ipv6Remote ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeInterfaceId,
            settings.transixStaticIpSettings.ipv6InterfaceId ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeIpv4GlobalAddress,
            settings.transixStaticIpSettings.ipv4Address ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeUpdateUserId,
            settings.transixStaticIpSettings.updateUserId ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeUpdatePassword,
            _secretLabel(settings.transixStaticIpSettings.updatePassword),
          ),
        ],
      AutoIPoEMode.asahiNetStaticIp => [
          _infoRow(
            loc(context).autoIpoeAuthenticationKey,
            settings.asahiNetStaticIpSettings.authenticationKey ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeAuthenticationPassword,
            _secretLabel(
              settings.asahiNetStaticIpSettings.authenticationPassword,
            ),
          ),
        ],
      AutoIPoEMode.xpassStaticIp => [
          _infoRow(
            loc(context).autoIpoeDdnsFqdn,
            settings.xpassStaticIpSettings.fqdn ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeDdnsId,
            settings.xpassStaticIpSettings.ddnsId ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeDdnsPassword,
            _secretLabel(settings.xpassStaticIpSettings.ddnsPassword),
          ),
          _infoRow(
            loc(context).autoIpoeBasicAuthId,
            settings.xpassStaticIpSettings.basicAuthId ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeBasicAuthPassword,
            _secretLabel(settings.xpassStaticIpSettings.basicAuthPassword),
          ),
          _infoRow(
            loc(context).autoIpoeDdnsUpdateUrl,
            settings.xpassStaticIpSettings.ddnsUpdateUrl ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeTunnelDestination,
            settings.xpassStaticIpSettings.ipv6Remote ?? '-',
          ),
          _infoRow(
            loc(context).autoIpoeIpv4GlobalAddress,
            settings.xpassStaticIpSettings.ipv4Address ?? '-',
          ),
        ],
      AutoIPoEMode.ocxHikariV6ixStaticIp => [
          _infoRow(
            loc(context).autoIpoeDetails,
            loc(context).autoIpoeNoAdditionalParameters,
          ),
        ],
      AutoIPoEMode.disabled => [],
    };
  }

  Widget _buildEditing() {
    final selectedMode = widget.settings.selectedMode == AutoIPoEMode.disabled
        ? AutoIPoEMode.auto
        : widget.settings.selectedMode;
    final selectedModeFieldGroup = _fieldGroupForMode(selectedMode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _highlightedGroup(
          key: const ValueKey('autoIpoeModeFieldGroup'),
          highlighted: widget.highlightedFieldGroup == AutoIPoEFieldGroup.mode,
          child: Padding(
            padding: _inputPadding,
            child: AppDropdownButton<AutoIPoEMode>(
              title: loc(context).autoIpoeMode,
              selected: selectedMode,
              items: _editableModes,
              label: _modeLabel,
              onChanged: (value) {
                widget.onChanged(
                  widget.settings.copyWith(
                    isEnabled: true,
                    selectedMode: value,
                  ),
                );
              },
            ),
          ),
        ),
        _highlightedGroup(
          key: ValueKey('autoIpoe${selectedMode.value}FieldGroup'),
          highlighted: selectedModeFieldGroup != AutoIPoEFieldGroup.none &&
              selectedModeFieldGroup == widget.highlightedFieldGroup,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _buildModeEditor(selectedMode),
          ),
        ),
      ],
    );
  }

  AutoIPoEFieldGroup _fieldGroupForMode(AutoIPoEMode mode) {
    return switch (mode) {
      AutoIPoEMode.biglobeStaticIp => AutoIPoEFieldGroup.biglobeStaticIp,
      AutoIPoEMode.standardIpip => AutoIPoEFieldGroup.standardIpip,
      AutoIPoEMode.v6PlusStaticIp => AutoIPoEFieldGroup.v6PlusStaticIp,
      AutoIPoEMode.transixStaticIp => AutoIPoEFieldGroup.transixStaticIp,
      AutoIPoEMode.asahiNetStaticIp => AutoIPoEFieldGroup.asahiNetStaticIp,
      AutoIPoEMode.xpassStaticIp => AutoIPoEFieldGroup.xpassStaticIp,
      _ => AutoIPoEFieldGroup.none,
    };
  }

  Widget _highlightedGroup({
    required Key key,
    required bool highlighted,
    required Widget child,
  }) {
    if (!highlighted) {
      return KeyedSubtree(key: key, child: child);
    }
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      key: key,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: Spacing.small2),
      padding: const EdgeInsets.all(Spacing.small3),
      decoration: BoxDecoration(
        border: Border.all(color: errorColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const AppGap.small2(),
          AppText.bodySmall(
            loc(context).autoIpoeFieldGroupNeedsAttention,
            color: errorColor,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModeEditor(AutoIPoEMode mode) {
    final settings = widget.settings;
    return switch (mode) {
      AutoIPoEMode.auto => [
          _infoRow(
            loc(context).autoIpoeAutoDetection,
            loc(context).autoIpoeNoAdditionalParametersRequired,
          ),
        ],
      AutoIPoEMode.biglobeStaticIp => [
          _biglobeCredentialField(
            key: const ValueKey('autoIpoeBiglobeUserId'),
            label: loc(context).autoIpoeUserId,
            controller: _biglobeUserIdController,
            hasStoredValue:
                settings.biglobeStaticIpSettings.userId.hasStoredValue,
            obscureText: false,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                biglobeStaticIpSettings:
                    settings.biglobeStaticIpSettings.copyWith(
                  userId: _secretFromInput(
                    settings.biglobeStaticIpSettings.userId,
                    value,
                  ),
                ),
              ),
            ),
          ),
          _biglobeCredentialField(
            key: const ValueKey('autoIpoeBiglobePassword'),
            label: loc(context).password,
            controller: _biglobePasswordController,
            hasStoredValue:
                settings.biglobeStaticIpSettings.userPassword.hasStoredValue,
            obscureText: true,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                biglobeStaticIpSettings:
                    settings.biglobeStaticIpSettings.copyWith(
                  userPassword: _secretFromInput(
                    settings.biglobeStaticIpSettings.userPassword,
                    value,
                  ),
                ),
              ),
            ),
          ),
        ],
      AutoIPoEMode.standardIpip => [
          _textField(
            label: loc(context).autoIpoeIpv6Remote,
            controller: _standardIpv6RemoteController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                standardIpipSettings: settings.standardIpipSettings.copyWith(
                  ipv6Remote: value,
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeInterfaceId,
            controller: _standardIpv6InterfaceIdController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                standardIpipSettings: settings.standardIpipSettings.copyWith(
                  ipv6InterfaceId: value,
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeIpv4Address,
            controller: _standardIpv4AddressController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                standardIpipSettings: settings.standardIpipSettings.copyWith(
                  ipv4Address: value,
                ),
              ),
            ),
          ),
        ],
      AutoIPoEMode.v6PlusStaticIp => [
          _textField(
            label: loc(context).autoIpoeBrIpv6Address,
            controller: _v6PlusIpv6RemoteController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                v6PlusStaticIpSettings:
                    settings.v6PlusStaticIpSettings.copyWith(
                  ipv6Remote: value,
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeInterfaceId,
            controller: _v6PlusIpv6InterfaceIdController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                v6PlusStaticIpSettings:
                    settings.v6PlusStaticIpSettings.copyWith(
                  ipv6InterfaceId: value,
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeIpv4GlobalAddress,
            controller: _v6PlusIpv4AddressController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                v6PlusStaticIpSettings:
                    settings.v6PlusStaticIpSettings.copyWith(
                  ipv4Address: value,
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeUserId,
            controller: _v6PlusUserIdController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                v6PlusStaticIpSettings:
                    settings.v6PlusStaticIpSettings.copyWith(
                  userId: value,
                ),
              ),
            ),
          ),
          _passwordField(
            label: loc(context).password,
            controller: _v6PlusPasswordController,
            hasStoredValue:
                settings.v6PlusStaticIpSettings.userPassword.hasStoredValue,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                v6PlusStaticIpSettings:
                    settings.v6PlusStaticIpSettings.copyWith(
                  userPassword: _secretFromInput(
                    settings.v6PlusStaticIpSettings.userPassword,
                    value,
                  ),
                ),
              ),
            ),
          ),
        ],
      AutoIPoEMode.ocnVirtualConnectStaticIp => [
          _infoRow(
            loc(context).autoIpoeDetails,
            loc(context).autoIpoeNoAdditionalParametersRequired,
          ),
        ],
      AutoIPoEMode.transixStaticIp => [
          _textField(
            label: loc(context).autoIpoeIpv6TunnelBr,
            controller: _transixIpv6RemoteController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                transixStaticIpSettings: settings.transixStaticIpSettings
                    .copyWith(ipv6Remote: value),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeInterfaceId,
            controller: _transixIpv6InterfaceIdController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                transixStaticIpSettings: settings.transixStaticIpSettings
                    .copyWith(ipv6InterfaceId: value),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeIpv4GlobalAddress,
            controller: _transixIpv4AddressController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                transixStaticIpSettings: settings.transixStaticIpSettings
                    .copyWith(ipv4Address: value),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeUpdateUserId,
            controller: _transixUpdateUserIdController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                transixStaticIpSettings: settings.transixStaticIpSettings
                    .copyWith(updateUserId: value),
              ),
            ),
          ),
          _passwordField(
            label: loc(context).autoIpoeUpdatePassword,
            controller: _transixUpdatePasswordController,
            hasStoredValue:
                settings.transixStaticIpSettings.updatePassword.hasStoredValue,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                transixStaticIpSettings:
                    settings.transixStaticIpSettings.copyWith(
                  updatePassword: _secretFromInput(
                    settings.transixStaticIpSettings.updatePassword,
                    value,
                  ),
                ),
              ),
            ),
          ),
        ],
      AutoIPoEMode.asahiNetStaticIp => [
          _textField(
            label: loc(context).autoIpoeAuthenticationKey,
            controller: _asahiAuthKeyController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                asahiNetStaticIpSettings: settings.asahiNetStaticIpSettings
                    .copyWith(authenticationKey: value),
              ),
            ),
          ),
          _passwordField(
            label: loc(context).autoIpoeAuthenticationPassword,
            controller: _asahiAuthPasswordController,
            hasStoredValue: settings
                .asahiNetStaticIpSettings.authenticationPassword.hasStoredValue,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                asahiNetStaticIpSettings:
                    settings.asahiNetStaticIpSettings.copyWith(
                  authenticationPassword: _secretFromInput(
                    settings.asahiNetStaticIpSettings.authenticationPassword,
                    value,
                  ),
                ),
              ),
            ),
          ),
        ],
      AutoIPoEMode.xpassStaticIp => [
          _textField(
            label: loc(context).autoIpoeDdnsFqdn,
            controller: _xpassFqdnController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                xpassStaticIpSettings: settings.xpassStaticIpSettings.copyWith(
                  fqdn: value,
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeDdnsId,
            controller: _xpassDdnsIdController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                xpassStaticIpSettings: settings.xpassStaticIpSettings.copyWith(
                  ddnsId: value,
                ),
              ),
            ),
          ),
          _passwordField(
            label: loc(context).autoIpoeDdnsPassword,
            controller: _xpassDdnsPasswordController,
            hasStoredValue:
                settings.xpassStaticIpSettings.ddnsPassword.hasStoredValue,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                xpassStaticIpSettings: settings.xpassStaticIpSettings.copyWith(
                  ddnsPassword: _secretFromInput(
                    settings.xpassStaticIpSettings.ddnsPassword,
                    value,
                  ),
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeBasicAuthId,
            controller: _xpassBasicAuthIdController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                xpassStaticIpSettings: settings.xpassStaticIpSettings.copyWith(
                  basicAuthId: value,
                ),
              ),
            ),
          ),
          _passwordField(
            label: loc(context).autoIpoeBasicAuthPassword,
            controller: _xpassBasicAuthPasswordController,
            hasStoredValue:
                settings.xpassStaticIpSettings.basicAuthPassword.hasStoredValue,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                xpassStaticIpSettings: settings.xpassStaticIpSettings.copyWith(
                  basicAuthPassword: _secretFromInput(
                    settings.xpassStaticIpSettings.basicAuthPassword,
                    value,
                  ),
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeDdnsUpdateUrl,
            controller: _xpassUpdateUrlController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                xpassStaticIpSettings: settings.xpassStaticIpSettings.copyWith(
                  ddnsUpdateUrl: value,
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeTunnelDestination,
            controller: _xpassIpv6RemoteController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                xpassStaticIpSettings: settings.xpassStaticIpSettings.copyWith(
                  ipv6Remote: value,
                ),
              ),
            ),
          ),
          _textField(
            label: loc(context).autoIpoeIpv4GlobalAddress,
            controller: _xpassIpv4AddressController,
            onChanged: (value) => widget.onChanged(
              settings.copyWith(
                xpassStaticIpSettings: settings.xpassStaticIpSettings.copyWith(
                  ipv4Address: value,
                ),
              ),
            ),
          ),
        ],
      AutoIPoEMode.ocxHikariV6ixStaticIp => [
          _infoRow(
            _modeLabel(AutoIPoEMode.ocxHikariV6ixStaticIp),
            loc(context).autoIpoeNoAdditionalParametersRequired,
          ),
        ],
      AutoIPoEMode.disabled => [],
    };
  }
}
