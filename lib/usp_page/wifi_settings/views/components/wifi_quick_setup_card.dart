import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Card for Quick Setup mode — displays a single aggregated Main or Guest
/// network with only Name, Password, and Security mode fields.
///
/// Reads from [settings.current.quickSetupMain] / [settings.current.quickSetupGuest]
/// so pending edits are reflected immediately. All field edits call
/// [updateQuickSetupField] on the provider (staged — not written to firmware
/// until the page-level Save button is tapped).
///
/// Password shows a required indicator (red `(Required)`) until the user
/// enters a valid passphrase, because TR-181 cannot return the current value.
class WifiQuickSetupCard extends ConsumerWidget {
  final bool isGuest;
  final bool lastInRow;

  const WifiQuickSetupCard({
    super.key,
    required this.isGuest,
    this.lastInRow = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      uspWifiSettingsProvider.select((s) => isGuest
          ? s.settings.current.quickSetupGuest
          : s.settings.current.quickSetupMain),
    );

    if (pending == null) return const SizedBox.shrink();

    final passwordEntered = pending.password.isNotEmpty;

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
            // ── Header + enable toggle ────────────────────────────────────
            _QuickSetupTile(
              title: isGuest ? 'Guest' : 'Main',
              trailing: AppSwitch(
                value: pending.enabled,
                onChanged: (v) => ref
                    .read(uspWifiSettingsProvider.notifier)
                    .updateQuickSetupField(isGuest: isGuest, enabled: v),
              ),
            ),
            // ── Name ─────────────────────────────────────────────────────
            const Divider(),
            _QuickSetupTile(
              title: 'Name',
              description: pending.ssid.isNotEmpty ? pending.ssid : '(No SSID)',
              trailing: const AppIcon.font(AppFontIcons.edit),
              onTap: () => _editSsid(context, ref, pending.ssid),
            ),
            // ── Password — required indicator until entered ────────────────
            const Divider(),
            _QuickSetupTile(
              title: 'Password',
              description: passwordEntered ? '\u2022' * 12 : '(Required)',
              descriptionColor:
                  passwordEntered ? null : Theme.of(context).colorScheme.error,
              trailing: const AppIcon.font(AppFontIcons.edit),
              onTap: () => _editPassword(context, ref, pending.password),
            ),
            // ── Security mode ─────────────────────────────────────────────
            if (pending.supportedSecurityModes.isNotEmpty) ...[
              const Divider(),
              _QuickSetupTile(
                title: 'Security mode',
                description: pending.securityMode,
                trailing: const AppIcon.font(AppFontIcons.edit),
                onTap: () => _editSecurityMode(
                  context,
                  ref,
                  pending.securityMode,
                  pending.supportedSecurityModes,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit modals — write to settings.current via updateQuickSetupField
  // ---------------------------------------------------------------------------

  Future<void> _editSsid(
      BuildContext context, WidgetRef ref, String currentSsid) async {
    final controller = TextEditingController(text: currentSsid);
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
    if (result != null && result != currentSsid && context.mounted) {
      ref.read(uspWifiSettingsProvider.notifier).updateQuickSetupField(
            isGuest: isGuest,
            ssid: result,
          );
    }
  }

  Future<void> _editPassword(
      BuildContext context, WidgetRef ref, String currentPassword) async {
    final controller = TextEditingController(text: currentPassword);
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
      ref.read(uspWifiSettingsProvider.notifier).updateQuickSetupField(
            isGuest: isGuest,
            password: result,
          );
    }
  }

  Future<void> _editSecurityMode(
    BuildContext context,
    WidgetRef ref,
    String currentMode,
    List<String> supportedModes,
  ) async {
    String selected = currentMode;
    final result = await showSimpleAppDialog<String>(
      context,
      title: 'Security mode',
      content: StatefulBuilder(
        builder: (ctx, setState) => AppRadioList<String>(
          selected: selected,
          items: supportedModes
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
    if (result != null && result != currentMode && context.mounted) {
      ref.read(uspWifiSettingsProvider.notifier).updateQuickSetupField(
            isGuest: isGuest,
            securityMode: result,
          );
    }
  }
}

// ---------------------------------------------------------------------------
// Private tile widget
// ---------------------------------------------------------------------------

class _QuickSetupTile extends StatelessWidget {
  final String title;
  final String? description;
  final Color? descriptionColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _QuickSetupTile({
    required this.title,
    this.description,
    this.descriptionColor,
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
                    AppText.labelLarge(
                      description!,
                      color: descriptionColor,
                    ),
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
