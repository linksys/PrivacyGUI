import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/ipv6/automatic_ipv6_form.dart';
import 'base_ipv6_wan_form.dart';

class IPv6WanFormFactory {
  /// Creates the appropriate IPv6 WAN form widget based on the IPv6 setting.
  ///
  /// [type] The type of IPv6 connection.
  /// [isEditing] Whether the form should be in edit mode.
  static Widget create({
    required WanIPv6Type type,
    required bool isEditing,
  }) {
    switch (type) {
      case WanIPv6Type.automatic:
        return AutomaticIPv6Form(
          isEditing: isEditing,
        );
      case WanIPv6Type.static:
      case WanIPv6Type.bridge:
      case WanIPv6Type.sixRdTunnel:
      case WanIPv6Type.slaac:
      case WanIPv6Type.dhcpv6:
      case WanIPv6Type.pppoe:
      case WanIPv6Type.passThrough:
        // Return a basic form for unsupported types
        return _UnsupportedIPv6Form(
          isEditing: isEditing,
        );
    }
  }
}

class _UnsupportedIPv6Form extends BaseIPv6WanForm {
  const _UnsupportedIPv6Form({
    required super.isEditing,
  });

  @override
  ConsumerState<_UnsupportedIPv6Form> createState() =>
      _UnsupportedIPv6FormState();
}

class _UnsupportedIPv6FormState
    extends BaseIPv6WanFormState<_UnsupportedIPv6Form> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget buildEditableFields(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    final isValidCombination = state.status.supportedWANCombinations.any(
        (combine) =>
            combine.wanType ==
                state.settings.current.ipv4Setting.ipv4ConnectionType &&
            combine.wanIPv6Type ==
                state.settings.current.ipv6Setting.ipv6ConnectionType);

    return !isValidCombination
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Unsupported IPv6 connection type: ${state.current.ipv6Setting.ipv6ConnectionType}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget buildDisplayFields(BuildContext context) {
    final state = ref.watch(internetSettingsProvider);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Unsupported IPv6 connection type: ${state.current.ipv6Setting.ipv6ConnectionType}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
