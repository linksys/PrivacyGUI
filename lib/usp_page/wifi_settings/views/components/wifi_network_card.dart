import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Card for a single WiFi network, styled after the main wifi_settings page.
///
/// - Each field is displayed as label + value + pencil icon (tap to edit via modal)
/// - Password row shows a read-only masked field with show/hide toggle + pencil
/// - Enable/Broadcast SSID are immediate toggles (no modal)
/// - Channel Width and Channel are display-only (Radio mutations not yet implemented)
/// - [lastInRow] controls right padding in the Table grid layout
class WifiNetworkCard extends ConsumerStatefulWidget {
  final WifiNetworkUIModel network;
  final bool lastInRow;

  const WifiNetworkCard({
    super.key,
    required this.network,
    this.lastInRow = false,
  });

  @override
  ConsumerState<WifiNetworkCard> createState() => _WifiNetworkCardState();
}

class _WifiNetworkCardState extends ConsumerState<WifiNetworkCard> {
  late TextEditingController _passwordDisplayController;
  bool _obscurePassphrase = true;

  @override
  void initState() {
    super.initState();
    _passwordDisplayController =
        TextEditingController(text: widget.network.keyPassphrase);
  }

  @override
  void didUpdateWidget(WifiNetworkCard old) {
    super.didUpdateWidget(old);
    if (old.network.keyPassphrase != widget.network.keyPassphrase) {
      _passwordDisplayController.text = widget.network.keyPassphrase;
    }
  }

  @override
  void dispose() {
    _passwordDisplayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.network;
    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.lg,
        right: widget.lastInRow ? 0 : context.layoutGutter,
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
              title: n.isGuest ? 'Guest' : n.bandDisplayName,
              trailing: AppSwitch(
                value: n.enabled,
                onChanged: (v) => ref
                    .read(uspWifiSettingsProvider.notifier)
                    .toggleNetwork(n.ssidInstancePath, v),
              ),
            ),
            // ── WiFi name ─────────────────────────────────────────────────
            const Divider(),
            _WifiTile(
              title: n.isGuest ? 'Guest WiFi Name' : 'WiFi name',
              description: n.ssid.isNotEmpty ? n.ssid : '(No SSID)',
              trailing: const AppIcon.font(AppFontIcons.edit),
              onTap: () => _editSsid(context, n),
            ),
            // ── WiFi password ──────────────────────────────────────────────
            const Divider(),
            _buildPasswordRow(context, n),
            // ── Security mode (main networks only) ────────────────────────
            if (!n.isGuest && n.supportedSecurityModes.isNotEmpty) ...[
              const Divider(),
              _WifiTile(
                title: 'Security mode',
                description: n.securityMode,
                trailing: const AppIcon.font(AppFontIcons.edit),
                onTap: () => _editSecurityMode(context, n),
              ),
            ],
            // ── WiFi Mode (main networks with known supported standards) ──
            if (!n.isGuest && n.supportedStandards.isNotEmpty) ...[
              const Divider(),
              _WifiTile(
                title: 'WiFi Mode',
                description: _wifiModeDisplayName(n.operatingStandards),
                trailing: n.radioInstancePath != null
                    ? const AppIcon.font(AppFontIcons.edit)
                    : null,
                onTap: n.radioInstancePath != null
                    ? () => _editWifiMode(context, n)
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
                          .toggleBroadcastSsid(n.accessPointInstancePath!, v)
                      : null,
                ),
              ),
              const Divider(),
              _WifiTile(
                title: 'Channel Width',
                description: n.channelBandwidth.isNotEmpty
                    ? n.channelBandwidth
                    : 'Auto',
                trailing: n.radioInstancePath != null
                    ? const AppIcon.font(AppFontIcons.edit)
                    : null,
                onTap: n.radioInstancePath != null
                    ? () => _editChannelWidth(context, n)
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
                    ? () => _editChannel(context, n)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Password row — read-only masked field + show/hide icon + pencil
  // ---------------------------------------------------------------------------

  Widget _buildPasswordRow(BuildContext context, WifiNetworkUIModel n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                    n.isGuest ? 'Guest WiFi Password' : 'WiFi password'),
                AppGap.xs(),
                AppTextFormField(
                  controller: _passwordDisplayController,
                  readOnly: true,
                  obscureText: _obscurePassphrase,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassphrase
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassphrase = !_obscurePassphrase),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.md, bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => _editPassword(context, n),
              child: const AppIcon.font(AppFontIcons.edit),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit modals
  // ---------------------------------------------------------------------------

  Future<void> _editSsid(BuildContext context, WifiNetworkUIModel n) async {
    final controller = TextEditingController(text: n.ssid);
    final result = await showSubmitAppDialog<String>(
      context,
      title: n.isGuest ? 'Guest WiFi Name' : 'WiFi name',
      contentBuilder: (ctx, setState, onSubmit) => AppTextFormField(
        controller: controller,
        label: n.isGuest ? 'Guest WiFi Name' : 'WiFi name',
        onChanged: (_) => setState(() {}),
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => controller.text.trim().isNotEmpty,
    );
    if (result != null && result != n.ssid && mounted) {
      await ref.read(uspWifiSettingsProvider.notifier).updateNetworkSettings(
            ssidInstancePath: n.ssidInstancePath,
            newSsid: result,
          );
    }
  }

  Future<void> _editPassword(BuildContext context, WifiNetworkUIModel n) async {
    final controller = TextEditingController(text: n.keyPassphrase);
    bool obscure = true;
    final result = await showSubmitAppDialog<String>(
      context,
      title: n.isGuest ? 'Guest WiFi Password' : 'WiFi password',
      contentBuilder: (ctx, setState, onSubmit) => StatefulBuilder(
        builder: (ctx2, setLocal) => AppTextFormField(
          controller: controller,
          label: n.isGuest ? 'Guest WiFi Password' : 'WiFi password',
          obscureText: obscure,
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
            onPressed: () => setLocal(() => obscure = !obscure),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => controller.text.isNotEmpty,
    );
    if (result != null && result != n.keyPassphrase && mounted) {
      await ref.read(uspWifiSettingsProvider.notifier).updateNetworkSettings(
            ssidInstancePath: n.ssidInstancePath,
            apInstancePath: n.accessPointInstancePath,
            newPassphrase: result,
          );
    }
  }

  Future<void> _editSecurityMode(
      BuildContext context, WifiNetworkUIModel n) async {
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
    if (result != null && result != n.securityMode && mounted) {
      await ref.read(uspWifiSettingsProvider.notifier).updateNetworkSettings(
            ssidInstancePath: n.ssidInstancePath,
            apInstancePath: n.accessPointInstancePath,
            newSecurityMode: result,
          );
    }
  }

  // ---------------------------------------------------------------------------
  // WiFi Mode helpers
  //
  // Linksys firmware accepts/returns concatenated standard letters:
  //   e.g. "anacax", "bgn", "mixed"
  //
  // Options are derived dynamically from SupportedStandards — no hardcoding.
  // ---------------------------------------------------------------------------

  /// Maps known firmware value → human-readable label.
  static const _wifiModeLabels = {
    'b':       '802.11b Only',
    'bg':      '802.11b/g Only',
    'bgn':     '802.11b/g/n Only',
    'bgnax':   '802.11b/g/n/ax Only',
    'a':       '802.11a Only',
    'an':      '802.11a/n Only',
    'anac':    '802.11a/n/ac Only',
    'anacax':  '802.11a/n/ac/ax Only',
    'mixed':   'Mixed',
  };

  /// Standard letters in introduction order — used for sort-then-join.
  static const _standardsOrder = ['b', 'g', 'a', 'n', 'ac', 'ax', 'be'];

  /// Extracts individual standard letters from [raw].
  ///
  /// Handles TR-181 comma-separated ("a,n,ac,ax") and firmware
  /// concatenated ("anacax") formats.
  Set<String> _parseSupportedSet(String raw) {
    if (raw.isEmpty) return {};
    final lower = raw.toLowerCase().trim();
    if (lower.contains(',')) {
      return lower.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    }
    // Firmware concatenated — longest-match extraction (multi-char tokens first).
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

  /// Normalises [raw] to the firmware concatenated format.
  ///
  ///   "a,n,ac,ax" → "anacax"   (TR-181 format)
  ///   "anacax"    → "anacax"   (already firmware format)
  ///   ""          → "mixed"
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

  /// Builds the option list from [supportedStandards].
  ///
  /// Handles two formats returned by Linksys firmware:
  ///
  ///   A) Already a list of firmware keys:  "bg,bgn,bgnax,mixed"
  ///      → use tokens directly (all are known labels).
  ///
  ///   B) Individual standard letters:       "b,g,n,ax"
  ///      → sort, build cumulative joins, keep known labels, append "mixed".
  List<String> _wifiModeOptions(String supportedStandards) {
    if (supportedStandards.isEmpty) return ['mixed'];

    final tokens = supportedStandards
        .toLowerCase()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Case A: every token is already a known firmware key
    if (tokens.every(_wifiModeLabels.containsKey)) {
      return tokens;
    }

    // Case B: tokens are individual standard letters — build cumulative options
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

  /// Display label for [value] (normalises first).
  String _wifiModeDisplayName(String value) {
    if (value.isEmpty) return 'Mixed';
    final normalized = _toFirmwareMode(value);
    return _wifiModeLabels[normalized] ?? value;
  }

  Future<void> _editWifiMode(
      BuildContext context, WifiNetworkUIModel n) async {
    final options = _wifiModeOptions(n.supportedStandards);
    if (options.isEmpty) return;

    final current = _toFirmwareMode(n.operatingStandards);
    String selected = options.contains(current) ? current : options.last;

    final items = options
        .map((value) => AppRadioListItem<String>(
              title: _wifiModeLabels[value] ?? value,
              value: value,
            ))
        .toList();

    final result = await showSimpleAppDialog<String>(
      context,
      title: 'WiFi Mode',
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: items,
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
    if (result != null && result != current && mounted) {
      await ref.read(uspWifiSettingsProvider.notifier).updateRadioSettings(
            radioInstancePath: n.radioInstancePath!,
            operatingStandards: result,
          );
    }
  }

  Future<void> _editChannelWidth(
      BuildContext context, WifiNetworkUIModel n) async {
    // Standard bandwidths per band (IEEE 802.11)
    final options = switch (n.band) {
      '2.4GHz' => ['Auto', '20MHz', '40MHz'],
      '6GHz' => ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'],
      _ => ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'], // 5GHz default
    };
    final current =
        n.channelBandwidth.isNotEmpty ? n.channelBandwidth : 'Auto';
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
    if (result != null && result != current && mounted) {
      await ref.read(uspWifiSettingsProvider.notifier).updateRadioSettings(
            radioInstancePath: n.radioInstancePath!,
            channelBandwidth: result == 'Auto' ? 'Auto' : result,
          );
    }
  }

  Future<void> _editChannel(
      BuildContext context, WifiNetworkUIModel n) async {
    // "Auto" = autoChannelEnable true; integers = specific channel
    const autoLabel = 'Auto';
    final currentLabel = n.autoChannelEnable ? autoLabel : n.channel.toString();

    // Build items: Auto first, then all possible channels from router
    final channelItems = [
      AppRadioListItem<String>(title: autoLabel, value: autoLabel),
      ...n.possibleChannels.map(
        (ch) => AppRadioListItem<String>(
          title: ch.toString(),
          value: ch.toString(),
        ),
      ),
    ];

    String selected =
        channelItems.any((e) => e.value == currentLabel) ? currentLabel : autoLabel;

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
    if (result != null && result != currentLabel && mounted) {
      if (result == autoLabel) {
        await ref.read(uspWifiSettingsProvider.notifier).updateRadioSettings(
              radioInstancePath: n.radioInstancePath!,
              autoChannelEnable: true,
            );
      } else {
        final ch = int.tryParse(result);
        if (ch != null) {
          await ref.read(uspWifiSettingsProvider.notifier).updateRadioSettings(
                radioInstancePath: n.radioInstancePath!,
                channel: ch,
                autoChannelEnable: false,
              );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Private shared tile widget (label + optional value + optional trailing)
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
