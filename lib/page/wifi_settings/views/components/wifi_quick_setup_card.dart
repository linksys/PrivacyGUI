import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Card for Quick Setup mode — displays a single aggregated Main or Guest
/// network with only Name, Password, and Security mode fields.
///
/// Uses Card + Block pattern: AppCard as outer container, Block for each setting row.
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
    final original = ref.watch(
      uspWifiSettingsProvider.select((s) => isGuest
          ? s.settings.original.quickSetupGuest
          : s.settings.original.quickSetupMain),
    );

    if (pending == null) return const SizedBox.shrink();

    final passwordEntered = pending.password.isNotEmpty;
    final passwordRequired = pending.isPasswordRequired(original);

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
            // ── Header + enable toggle ────────────────────────────────────
            _SettingBlock(
              title: isGuest ? loc(context).guest : loc(context).main,
              trailing: AppSwitch(
                value: pending.enabled,
                onChanged: (v) => ref
                    .read(uspWifiSettingsProvider.notifier)
                    .updateQuickSetupField(isGuest: isGuest, enabled: v),
              ),
            ),
            // ── Name ─────────────────────────────────────────────────────
            _SettingBlock(
              title: loc(context).name,
              description:
                  pending.ssid.isNotEmpty ? pending.ssid : loc(context).noSsid,
              trailing: const AppIcon.font(AppFontIcons.edit),
              onTap: () => _editSsid(context, ref, pending.ssid),
            ),
            // ── Password & Security mode ─────────────────────────────────
            if (pending.supportedSecurityModes.isNotEmpty) ...[
              _SettingBlock(
                title: loc(context).password,
                description: passwordEntered
                    ? '•' * 12
                    : (passwordRequired
                        ? loc(context).requiredLabel
                        : loc(context).unchangedLabel),
                descriptionColor: (passwordRequired && !passwordEntered)
                    ? Theme.of(context).colorScheme.error
                    : null,
                trailing: const AppIcon.font(AppFontIcons.edit),
                onTap: () => _editPassword(context, ref, pending.password),
              ),
              _SettingBlock(
                title: loc(context).securityMode,
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
      title: loc(context).securityMode,
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
        AppButton.text(label: loc(context).cancel, onTap: () => context.pop()),
        AppButton.text(
            label: loc(context).ok, onTap: () => context.pop(selected)),
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
// Setting Block — Block-wrapped setting row
// ---------------------------------------------------------------------------

class _SettingBlock extends StatelessWidget {
  final String title;
  final String? description;
  final Color? descriptionColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingBlock({
    required this.title,
    this.description,
    this.descriptionColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: LayoutBlock(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
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
