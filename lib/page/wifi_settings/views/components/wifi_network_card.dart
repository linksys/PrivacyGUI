import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_channel_bonding.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Card for a single WiFi network in Advanced mode.
///
/// Uses Card + Block pattern: AppCard as outer container, Block for each setting row.
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Band header + enable toggle ──────────────────────────────
            SettingBlock(
              title: n.isGuest ? loc(context).guest : loc(context).main,
              value: n.bandDisplayName,
              semanticLabel: 'wifi-enable-${n.band}',
              trailing: AppSwitch(
                value: n.enabled,
                onChanged: (v) => ref
                    .read(uspWifiSettingsProvider.notifier)
                    .updateNetworkField(ssidInstancePath, enabled: v),
              ),
            ),
            // ── WiFi name ─────────────────────────────────────────────────
            SettingBlock(
              title: loc(context).name,
              value: n.ssid.isNotEmpty ? n.ssid : loc(context).noSsid,
              semanticLabel: 'wifi-name-${n.band}',
              trailing: const AppIcon.font(AppFontIcons.edit),
              onTap: () => _editSsid(context, ref, n),
            ),
            // ── WiFi password & Security mode ────────────────────────────
            // Shown for both main and guest whenever the AP reports supported
            // security modes. Guest security mode is editable too — consistent
            // with the Quick Setup card.
            if (n.supportedSecurityModes.isNotEmpty) ...[
              SettingBlock(
                title: loc(context).password,
                value: '•' * 12,
                trailing: const AppIcon.font(AppFontIcons.edit),
                onTap: () => _editPassword(context, ref, n),
              ),
              SettingBlock(
                title: loc(context).securityMode,
                value: n.securityMode,
                trailing: const AppIcon.font(AppFontIcons.edit),
                onTap: () => _editSecurityMode(context, ref, n),
              ),
            ],
            // ── WiFi Mode ──────────────────────────────────────────────────
            if (!n.isGuest && n.supportedStandards.isNotEmpty)
              SettingBlock(
                title: loc(context).wifiMode,
                value: _wifiModeDisplayName(context, n.operatingStandards),
                trailing: n.radioInstancePath != null
                    ? const AppIcon.font(AppFontIcons.edit)
                    : null,
                onTap: n.radioInstancePath != null
                    ? () => _editWifiMode(context, ref, n)
                    : null,
              ),
            // ── Broadcast SSID / Channel Width / Channel (main only) ──────
            if (!n.isGuest) ...[
              SettingBlock(
                title: loc(context).broadcastSSID,
                semanticLabel: 'wifi-broadcast-${n.band}',
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
              SettingBlock(
                title: loc(context).channelWidth,
                value: n.channelBandwidth.isNotEmpty
                    ? wifiDisplayValue(context, n.channelBandwidth)
                    : loc(context).auto,
                trailing: n.radioInstancePath != null
                    ? const AppIcon.font(AppFontIcons.edit)
                    : null,
                onTap: n.radioInstancePath != null
                    ? () => _editChannelWidth(context, ref, n)
                    : null,
              ),
              SettingBlock(
                title: loc(context).channel,
                value: wifiDisplayValue(context, n.channelDisplay),
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
      title: loc(context).name,
      contentBuilder: (ctx, setState, onSubmit) => AppTextFormField(
        controller: controller,
        label: loc(context).name,
        onChanged: (_) => setState(() {}),
      ),
      positiveLabel: loc(context).ok,
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
    final controller = TextEditingController(text: n.keyPassphrase);
    bool isValid = false;

    final passwordRules = [
      AppPasswordRule(
        label: loc(context).passwordLength8To63,
        validate: (text) => LengthRule(min: 8, max: 63).validate(text),
      ),
      AppPasswordRule(
        label: loc(context).printableCharsOnly,
        validate: (text) => WiFiPasswordRule(ignoreLength: true).validate(text),
      ),
    ];

    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).password,
      contentBuilder: (ctx, setState, onSubmit) => AppPasswordInput(
        controller: controller,
        label: loc(context).password,
        rules: passwordRules,
        onChanged: (_) {
          setState(() {
            isValid = passwordRules.every((r) => r.validate(controller.text));
          });
        },
      ),
      positiveLabel: loc(context).ok,
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
      title: loc(context).securityMode,
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: n.supportedSecurityModes
              .map((e) => AppRadioListItem<String>(
                  title: wifiDisplayValue(ctx, e), value: e))
              .toList(),
          onChanged: (_, value) {
            if (value != null) setState(() => selected = value);
          },
        ),
      ),
      actions: [
        AppButton.text(label: loc(context).cancel, onTap: () => context.pop()),
        AppButton.text(
            label: loc(context).ok, onTap: () => context.pop(selected)),
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

  String _wifiModeDisplayName(BuildContext context, String value) {
    if (value.isEmpty) return loc(context).mixed;
    return wifiDisplayValue(
        context, _wifiModeLabels[_toFirmwareMode(value)] ?? value);
  }

  Future<void> _editWifiMode(
      BuildContext context, WidgetRef ref, WifiNetworkUIModel n) async {
    final allOptions = _wifiModeOptions(n.supportedStandards);
    if (allOptions.isEmpty) return;

    final minStd = minStandardForBandwidth(n.channelBandwidth);
    final bwIdx = bandwidthOrder.indexOf(n.channelBandwidth);
    final options = minStd != null && bwIdx > 0
        ? allOptions.where((mode) {
            final maxBw = maxBandwidthForStandards(mode);
            return bandwidthOrder.indexOf(maxBw) >= bwIdx;
          }).toList()
        : allOptions;

    if (options.isEmpty) return;

    final current = _toFirmwareMode(n.operatingStandards);
    String selected = options.contains(current) ? current : options.last;

    final result = await showSimpleAppDialog<String>(
      context,
      title: loc(context).wifiMode,
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: options
              .map((value) => AppRadioListItem<String>(
                    title:
                        wifiDisplayValue(ctx, _wifiModeLabels[value] ?? value),
                    value: value,
                  ))
              .toList(),
          onChanged: (_, value) {
            if (value != null) setState(() => selected = value);
          },
        ),
      ),
      actions: [
        AppButton.text(label: loc(context).cancel, onTap: () => context.pop()),
        AppButton.text(
            label: loc(context).ok, onTap: () => context.pop(selected)),
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
    var allOptions = n.supportedBandwidths.isNotEmpty
        ? n.supportedBandwidths
        : switch (n.band) {
            '2.4GHz' => ['Auto', '20MHz', '40MHz'],
            '6GHz' => ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'],
            _ => ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'],
          };

    if (!allOptions.contains('Auto')) {
      allOptions = ['Auto', ...allOptions];
    }

    final maxBw = maxBandwidthForStandards(n.operatingStandards);
    final maxIdx = bandwidthIndex(maxBw);
    final options = allOptions.where((bw) {
      if (bw == 'Auto') return true;
      final idx = bandwidthOrder.indexOf(bw);
      return idx >= 0 && idx <= maxIdx;
    }).toList();

    final current = n.channelBandwidth.isNotEmpty ? n.channelBandwidth : 'Auto';
    String selected = options.contains(current) ? current : options.first;

    final result = await showSimpleAppDialog<String>(
      context,
      title: loc(context).channelWidth,
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: options.map((bw) {
            final chCount = n.availableChannelsPerBandwidth[bw]?.length;
            return AppRadioListItem<String>(
              title: wifiDisplayValue(ctx, bw),
              value: bw,
              descriptionWidget: chCount != null
                  ? AppText.bodySmall(loc(context).nChannelsAvailable(chCount))
                  : null,
            );
          }).toList(),
          onChanged: (_, value) {
            if (value != null) setState(() => selected = value);
          },
        ),
      ),
      actions: [
        AppButton.text(label: loc(context).cancel, onTap: () => context.pop()),
        AppButton.text(
            label: loc(context).ok, onTap: () => context.pop(selected)),
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

    final channelsForCurrentBw =
        n.availableChannelsPerBandwidth[n.channelBandwidth];
    final effectiveChannels =
        (channelsForCurrentBw != null && channelsForCurrentBw.isNotEmpty)
            ? channelsForCurrentBw
            : n.possibleChannels;

    final channelItems = [
      AppRadioListItem<String>(
          title: wifiDisplayValue(context, autoLabel), value: autoLabel),
      ...effectiveChannels.map(
        (ch) => AppRadioListItem<String>(
          title: ch.toString(),
          value: ch.toString(),
        ),
      ),
    ];

    String selected = channelItems.any((e) => e.value == currentLabel)
        ? currentLabel
        : autoLabel;
    // Baseline for the no-op check: the selection the dialog opens on. A stored
    // channel that isn't selectable — e.g. a DFS channel the firmware left set
    // while DFS is off — opens as Auto, and confirming without moving must NOT
    // be treated as a change.
    final initialSelected = selected;

    final result = await showSimpleAppDialog<String>(
      context,
      title: loc(context).channel,
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
        AppButton.text(label: loc(context).cancel, onTap: () => context.pop()),
        AppButton.text(
            label: loc(context).ok, onTap: () => context.pop(selected)),
      ],
    );
    if (result != null && result != initialSelected && context.mounted) {
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
