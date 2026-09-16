import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart'
    hide FirmwareImageUIModel;
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Which router this is, and what its boot slots hold.
///
/// **Shared by both firmware pages, and the slots are why it belongs on the OTA
/// page too.** A router-side OTA install writes into the standby bank and reboots
/// into it — the same slot a manual upload lands in — so "slot 1 is running this,
/// slot 2 is where the next one goes" is the context for pressing Update Now, not
/// just for picking a file. Before this card the OTA page said nothing at all about
/// the firmware the router is currently running.
///
/// Deliberately no third row state for "the update will land here". The standby
/// row already is that row: `targetBank` is `FirmwareBanksData.availableBank`
/// (`available && !isActive`), so on a two-bank router the standby slot is the only
/// candidate and a separate badge would restate it. Nor does the incoming version
/// go on that row — the router does not hold it until the flash completes, and a
/// slot printing a version it cannot boot reads as if it did.
///
/// Takes plain values rather than reading providers, so the two pages can differ on
/// how they decide [banksUnreadable] — the same split `FirmwareStateUnreadableCard`
/// documents, and for the same reason: the OTA page needs a conjunction there and
/// this page does not. Both feed it from `firmwareBanksDataProvider`, the L1 source
/// of truth.
class FirmwareRouterStatusCard extends StatelessWidget {
  const FirmwareRouterStatusCard({
    super.key,
    required this.systemInfo,
    required this.banks,
    required this.isLoadingBanks,
    required this.banksUnreadable,
  });

  /// Model name, serial and the image to draw. Null renders no header at all
  /// rather than placeholders: this read is not the one the page is about, and both
  /// callers are useful with only the banks half.
  final SystemInfoUIModel? systemInfo;

  /// **`FirmwareBanksData.physicalBanks`, never `banks`.** This card draws one boot
  /// slot per row, and the virtual OTA instance is not a slot — rendered here it
  /// would claim a third bank and print the version the router could update *to* as
  /// if it already held it.
  final List<FirmwareImageUIModel> banks;

  final bool isLoadingBanks;

  /// The read failed, so an empty [banks] is the absence of an answer rather than
  /// an answer of "none".
  final bool banksUnreadable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRouterHeader(context),
          Divider(height: AppSpacing.xl * 2, color: scheme.outlineVariant),
          AppText.labelLarge(loc(context).firmwareBanks),
          AppGap.md(),
          if (isLoadingBanks)
            _buildLoadingBanks(context)
          // Before the empty check, because an unreadable list is also an empty
          // one. A dash rather than a sentence: the card below this one already
          // says the router could not be asked, and any sentence here would either
          // repeat it or make a claim this read did not support.
          else if (banksUnreadable)
            AppText.bodyMedium('—', color: scheme.onSurfaceVariant)
          else if (banks.isEmpty)
            AppText.bodyMedium(loc(context).noFirmwareBanksReported)
          else
            _buildBanksList(context),
        ],
      ),
    );
  }

  Widget _buildRouterHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = systemInfo;
    if (info == null) {
      return const SizedBox.shrink();
    }
    final iconName = routerIconTestByModel(
      modelNumber: info.modelName,
      hardwareVersion: info.hardwareVersion,
    );
    return Row(
      children: [
        Image(
          image: DeviceImageHelper.getRouterImage(iconName, xl: false),
          width: 56,
          height: 56,
        ),
        AppGap.md(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleMedium(info.modelName),
              AppGap.xs(),
              AppText.bodySmall(
                info.serialNumber,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingBanks(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16, height: 16, child: AppLoader()),
        AppGap.md(),
        AppText.bodyMedium(loc(context).loading),
      ],
    );
  }

  Widget _buildBanksList(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < banks.length; i++) ...[
          _BankRow(bank: banks[i]),
          if (i < banks.length - 1) AppGap.sm(),
        ],
      ],
    );
  }
}

/// Single bank row with left accent bar indicating active status.
class _BankRow extends StatelessWidget {
  const _BankRow({required this.bank});

  final FirmwareImageUIModel bank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = bank.isActive;
    final accentColor = isActive ? scheme.primary : scheme.outlineVariant;
    final bgColor = isActive
        ? scheme.primaryContainer.withValues(alpha: 0.15)
        : scheme.surfaceContainerLowest;
    final version = bank.version.isEmpty ? '(empty)' : bank.version;
    final slot = bank.instance;

    return Semantics(
      // Per-row E2E anchor so "slot N became Active" is expressible instead of
      // the whole banks card flattening to one string (PrivacyGUI-USP-E2E#114).
      // Matches the dynamic-hook convention (`pf-rule-enable-${...}`,
      // `admin-timezone-item-${...}`). The version/status/label inside stay
      // text-asserted: lint:ids exempts assertions once the row is anchorable.
      //
      // One anchor per slot per *page*, and that stays true now the card is on
      // both: the two pages are separate routes, so no frame holds two of these.
      identifier: 'firmware-bank-${bank.instance}',
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(width: 4, color: accentColor),
              AppGap.md(),
              // Slot badge
              _SlotBadge(number: slot, isActive: isActive),
              AppGap.md(),
              // Version + status
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.bodyMedium(version),
                      AppGap.xs(),
                      _StatusLabel(isActive: isActive),
                    ],
                  ),
                ),
              ),
              AppGap.md(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  const _SlotBadge({required this.number, required this.isActive});

  final int number;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isActive ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = isActive ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: AppText.labelLarge(
        number.toString(),
        color: fg,
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = isActive ? Icons.check_circle : Icons.circle_outlined;
    final color = isActive ? scheme.primary : scheme.outline;
    final label = isActive ? loc(context).active : loc(context).standby;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        AppGap.xs(),
        AppText.labelSmall(label, color: color),
      ],
    );
  }
}
