import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Card for a single WiFi network in Advanced mode.
///
/// Reads the effective (user-edited) model from [settings.current.networks]
/// so pending edits are reflected immediately. All field edits call
/// [updateNetworkField] on the provider (staged — not written to firmware
/// until the page-level Save button is tapped).
class WifiNetworkCard extends ConsumerWidget {
  final String ssidInstancePath;
  final bool lastInRow;

  const WifiNetworkCard({
    super.key,
    required this.ssidInstancePath,
    this.lastInRow = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the specific network from settings.current so edits rebuild.
    final n = ref.watch(
      uspWifiSettingsProvider.select((s) {
        try {
          return s.settings.current.networks.firstWhere(
            (net) => net.ssidInstancePath == ssidInstancePath,
          );
        } catch (_) {
          return null;
        }
      }),
    );

    if (n == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.lg,
        right: lastInRow ? 0 : context.layoutGutter,
      ),
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Band header + enable toggle ──────────────────────────────
            _WifiTile(
              title: n.isGuest ? 'Guest' : 'Main',
              description: n.bandDisplayName,
              trailing: AppSwitch(
                value: n.enabled,
                onChanged: (v) => ref
                    .read(uspWifiSettingsProvider.notifier)
                    .updateNetworkField(ssidInstancePath, enabled: v),
              ),
            ),
            // ── WiFi name ─────────────────────────────────────────────────
            const Divider(),
            _WifiTile(
              title: 'Name',
              description: n.ssid.isNotEmpty ? n.ssid : '(No SSID)',
              trailing: const AppIcon.font(AppFontIcons.edit),
              onTap: () => _editSsid(context, ref, n),
            ),
            // ── WiFi password — bullet dots + pencil ──────────────────────
            const Divider(),
            _WifiTile(
              title: 'Password',
              description: '\u2022' * 12,
              trailing: const AppIcon.font(AppFontIcons.edit),
              onTap: () => _editPassword(context, ref, n),
            ),
            // ── Security mode (main networks only) ────────────────────────
            if (!n.isGuest && n.supportedSecurityModes.isNotEmpty) ...[
              const Divider(),
              _WifiTile(
                title: 'Security mode',
                description: n.securityMode,
                trailing: const AppIcon.font(AppFontIcons.edit),
                onTap: () => _editSecurityMode(context, ref, n),
              ),
            ],
            // ── WiFi Mode ──────────────────────────────────────────────────
            if (!n.isGuest && n.supportedStandards.isNotEmpty) ...[
              const Divider(),
              _WifiTile(
                title: 'WiFi Mode',
                description: _wifiModeDisplayName(n.operatingStandards),
                trailing: n.radioInstancePath != null
                    ? const AppIcon.font(AppFontIcons.edit)
                    : null,
                onTap: n.radioInstancePath != null
                    ? () => _editWifiMode(context, ref, n)
                    : null,
              ),
            ],
            // ── Broadcast SSID / Channel Width / Channel (main only) ──────
            if (!n.isGuest) ...[
              const Divider(),
              _WifiTile(
                title: 'Broadcast SSID',
                trailing: AppSwitch(
                  value: n.ssidAdvertisementEnabled,
                  onChanged: n.accessPointInstancePath != null
                      ? (v) => ref
                          .read(uspWifiSettingsProvider.notifier)
                          .updateNetworkField(ssidInstancePath,
                              broadcastSsid: v)
                      : null,
                ),
              ),
              const Divider(),
              _WifiTile(
                title: 'Channel Width',
                description:
                    n.channelBandwidth.isNotEmpty ? n.channelBandwidth : 'Auto',
                trailing: n.radioInstancePath != null
                    ? const AppIcon.font(AppFontIcons.edit)
                    : null,
                onTap: n.radioInstancePath != null
                    ? () => _editChannelWidth(context, ref, n)
                    : null,
              ),
              const Divider(),
              _WifiTile(
                title: 'Channel',
                description: n.channelDisplay,
                trailing: n.radioInstancePath != null
                    ? const AppIcon.font(AppFontIcons.edit)
                    : null,
                onTap: n.radioInstancePath != null
                    ? () => _editChannel(context, ref, n)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit modals — write to settings.current via updateNetworkField
  // ---------------------------------------------------------------------------

  Future<void> _editSsid(
      BuildContext context, WidgetRef ref, WifiNetworkUIModel n) async {
    final controller = TextEditingController(text: n.ssid);
    final result = await showSubmitAppDialog<String>(
      context,
      title: 'Name',
      contentBuilder: (ctx, setState, onSubmit) => AppTextFormField(
        controller: controller,
        label: 'Name',
        onChanged: (_) => setState(() {}),
      ),
      positiveLabel: 'OK',
      event: () async => controller.text,
      checkPositiveEnabled: () => controller.text.trim().isNotEmpty,
    );
    if (result != null && result != n.ssid && context.mounted) {
      ref.read(uspWifiSettingsProvider.notifier).updateNetworkField(
            ssidInstancePath,
            ssid: result,
          );
    }
  }

  Future<void> _editPassword(
      BuildContext context, WidgetRef ref, WifiNetworkUIModel n) async {
    // Pre-fill with any already-staged password (n.keyPassphrase reflects current).
    final controller = TextEditingController(text: n.keyPassphrase);
    bool isValid = false;

    final passwordRules = [
      AppPasswordRule(
        label: '8 to 63 characters',
        validate: (text) => LengthRule(min: 8, max: 63).validate(text),
      ),
      AppPasswordRule(
        label: 'Printable characters only, no leading or trailing spaces',
        validate: (text) => WiFiPasswordRule(ignoreLength: true).validate(text),
      ),
    ];

    final result = await showSubmitAppDialog<String>(
      context,
      title: 'Password',
      contentBuilder: (ctx, setState, onSubmit) => AppPasswordInput(
        controller: controller,
        label: 'Password',
        rules: passwordRules,
        onChanged: (_) {
          setState(() {
            isValid = passwordRules.every((r) => r.validate(controller.text));
          });
        },
      ),
      positiveLabel: 'OK',
      event: () async => controller.text,
      checkPositiveEnabled: () => isValid,
    );
    if (result != null && context.mounted) {
      ref.read(uspWifiSettingsProvider.notifier).updateNetworkField(
            ssidInstancePath,
            password: result,
          );
    }
  }

  Future<void> _editSecurityMode(
      BuildContext context, WidgetRef ref, WifiNetworkUIModel n) async {
    String selected = n.securityMode;
    final result = await showSimpleAppDialog<String>(
      context,
      title: 'Security mode',
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: n.supportedSecurityModes
              .map((e) => AppRadioListItem<String>(title: e, value: e))
              .toList(),
          onChanged: (_, value) {
            if (value != null) setState(() => selected = value);
          },
        ),
      ),
      actions: [
        AppButton.text(label: 'Cancel', onTap: () => context.pop()),
        AppButton.text(label: 'OK', onTap: () => context.pop(selected)),
      ],
    );
    if (result != null && result != n.securityMode && context.mounted) {
      ref.read(uspWifiSettingsProvider.notifier).updateNetworkField(
            ssidInstancePath,
            securityMode: result,
          );
    }
  }

  // ---------------------------------------------------------------------------
  // WiFi Mode helpers
  // ---------------------------------------------------------------------------

  static const _wifiModeLabels = {
    'b': '802.11b Only',
    'bg': '802.11b/g Only',
    'bgn': '802.11b/g/n Only',
    'bgnax': '802.11b/g/n/ax Only',
    'a': '802.11a Only',
    'an': '802.11a/n Only',
    'anac': '802.11a/n/ac Only',
    'anacax': '802.11a/n/ac/ax Only',
    'mixed': 'Mixed',
  };

  static const _standardsOrder = ['b', 'g', 'a', 'n', 'ac', 'ax', 'be'];

  Set<String> _parseSupportedSet(String raw) {
    if (raw.isEmpty) return {};
    final lower = raw.toLowerCase().trim();
    if (lower.contains(',')) {
      return lower
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }
    const known = ['be', 'ax', 'ac', 'n', 'g', 'b', 'a'];
    final found = <String>{};
    var remaining = lower;
    for (final std in known) {
      while (remaining.contains(std)) {
        found.add(std);
        remaining = remaining.replaceFirst(std, '');
      }
    }
    return found;
  }

  String _toFirmwareMode(String raw) {
    if (raw.isEmpty) return 'mixed';
    final lower = raw.toLowerCase().trim();
    if (_wifiModeLabels.containsKey(lower)) return lower;
    final parts = lower
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort((a, b) =>
          _standardsOrder.indexOf(a).compareTo(_standardsOrder.indexOf(b)));
    final joined = parts.join('');
    return _wifiModeLabels.containsKey(joined) ? joined : 'mixed';
  }

  List<String> _wifiModeOptions(String supportedStandards) {
    if (supportedStandards.isEmpty) return ['mixed'];
    final tokens = supportedStandards
        .toLowerCase()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (tokens.every(_wifiModeLabels.containsKey)) return tokens;
    final supported = _parseSupportedSet(supportedStandards);
    if (supported.isEmpty) return ['mixed'];
    final sorted = supported.toList()
      ..sort((a, b) =>
          _standardsOrder.indexOf(a).compareTo(_standardsOrder.indexOf(b)));
    final options = <String>[];
    for (var i = 0; i < sorted.length; i++) {
      final key = sorted.sublist(0, i + 1).join('');
      if (_wifiModeLabels.containsKey(key)) options.add(key);
    }
    if (!options.contains('mixed')) options.add('mixed');
    return options;
  }

  String _wifiModeDisplayName(String value) {
    if (value.isEmpty) return 'Mixed';
    return _wifiModeLabels[_toFirmwareMode(value)] ?? value;
  }

  Future<void> _editWifiMode(
      BuildContext context, WidgetRef ref, WifiNetworkUIModel n) async {
    final options = _wifiModeOptions(n.supportedStandards);
    if (options.isEmpty) return;

    final current = _toFirmwareMode(n.operatingStandards);
    String selected = options.contains(current) ? current : options.last;

    final result = await showSimpleAppDialog<String>(
      context,
      title: 'WiFi Mode',
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: options
              .map((value) => AppRadioListItem<String>(
                    title: _wifiModeLabels[value] ?? value,
                    value: value,
                  ))
              .toList(),
          onChanged: (_, value) {
            if (value != null) setState(() => selected = value);
          },
        ),
      ),
      actions: [
        AppButton.text(label: 'Cancel', onTap: () => context.pop()),
        AppButton.text(label: 'OK', onTap: () => context.pop(selected)),
      ],
    );
    if (result != null && result != current && context.mounted) {
      ref.read(uspWifiSettingsProvider.notifier).updateNetworkField(
            ssidInstancePath,
            operatingStandards: result,
          );
    }
  }

  Future<void> _editChannelWidth(
      BuildContext context, WidgetRef ref, WifiNetworkUIModel n) async {
    final options = switch (n.band) {
      '2.4GHz' => ['Auto', '20MHz', '40MHz'],
      '6GHz' => ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'],
      _ => ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'],
    };
    final current = n.channelBandwidth.isNotEmpty ? n.channelBandwidth : 'Auto';
    String selected = options.contains(current) ? current : options.first;

    final result = await showSimpleAppDialog<String>(
      context,
      title: 'Channel Width',
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: options
              .map((e) => AppRadioListItem<String>(title: e, value: e))
              .toList(),
          onChanged: (_, value) {
            if (value != null) setState(() => selected = value);
          },
        ),
      ),
      actions: [
        AppButton.text(label: 'Cancel', onTap: () => context.pop()),
        AppButton.text(label: 'OK', onTap: () => context.pop(selected)),
      ],
    );
    if (result != null && result != current && context.mounted) {
      ref.read(uspWifiSettingsProvider.notifier).updateNetworkField(
            ssidInstancePath,
            channelBandwidth: result,
          );
    }
  }

  Future<void> _editChannel(
      BuildContext context, WidgetRef ref, WifiNetworkUIModel n) async {
    const autoLabel = 'Auto';
    final currentLabel = n.autoChannelEnable ? autoLabel : n.channel.toString();

    final channelItems = [
      AppRadioListItem<String>(title: autoLabel, value: autoLabel),
      ...n.possibleChannels.map(
        (ch) => AppRadioListItem<String>(
          title: ch.toString(),
          value: ch.toString(),
        ),
      ),
    ];

    String selected = channelItems.any((e) => e.value == currentLabel)
        ? currentLabel
        : autoLabel;

    final result = await showSimpleAppDialog<String>(
      context,
      title: 'Channel',
      scrollable: true,
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: channelItems,
          onChanged: (_, value) {
            if (value != null) setState(() => selected = value);
          },
        ),
      ),
      actions: [
        AppButton.text(label: 'Cancel', onTap: () => context.pop()),
        AppButton.text(label: 'OK', onTap: () => context.pop(selected)),
      ],
    );
    if (result != null && result != currentLabel && context.mounted) {
      if (result == autoLabel) {
        ref.read(uspWifiSettingsProvider.notifier).updateNetworkField(
              ssidInstancePath,
              autoChannel: true,
            );
      } else {
        final ch = int.tryParse(result);
        if (ch != null) {
          ref.read(uspWifiSettingsProvider.notifier).updateNetworkField(
                ssidInstancePath,
                channel: ch,
                autoChannel: false,
              );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Private shared tile widget
// ---------------------------------------------------------------------------

class _WifiTile extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _WifiTile({
    required this.title,
    this.description,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(title),
                  if (description != null) ...[
                    AppGap.xs(),
                    AppText.labelLarge(description!),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              AppGap.md(),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
