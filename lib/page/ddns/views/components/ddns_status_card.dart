import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';
import 'package:privacy_gui/page/ddns/providers/ddns_status_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The router's Internet IP address and what its last DDNS update came to.
///
/// Both values are read-only and move on their own, so they come from L1
/// providers rather than from the page's working copy: the status from
/// [ddnsStatusDataProvider] and the address from [wanDataProvider], each kept
/// current by its own push. It shows the router's applied state, not the
/// page's unsaved choice, and is absent while the router's client is
/// disabled or before the first read has answered.
class DdnsStatusCard extends ConsumerStatefulWidget {
  const DdnsStatusCard({super.key});

  @override
  ConsumerState<DdnsStatusCard> createState() => _DdnsStatusCardState();
}

class _DdnsStatusCardState extends ConsumerState<DdnsStatusCard> {
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    // A read that failed before any value arrived shows the card as unknown,
    // with its refresh icon, rather than hiding it: hidden would read the same
    // as a disabled client, and leave nothing to retry with.
    final async = ref.watch(ddnsStatusDataProvider);
    final status =
        async.valueOrNull ?? (async.hasError ? DdnsUpdateStatus.unknown : null);
    if (status == null || status == DdnsUpdateStatus.disabled) {
      return const SizedBox.shrink();
    }
    final wanAddress =
        ref.watch(wanDataProvider).valueOrNull?.model.ipAddress ?? '';
    final showPrivateNote = status == DdnsUpdateStatus.connectionFailed &&
        isPrivateIpv4Address(wanAddress);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AppText.titleSmall(loc(context).ddnsStatusTitle)),
              AppIconButton.icon(
                icon: AppIcon.font(AppFontIcons.refresh),
                identifier: 'ddns-status-refresh',
                semanticLabel: loc(context).refresh,
                isLoading: _refreshing,
                onTap: _refreshing ? null : _refresh,
              ),
            ],
          ),
          AppGap.md(),
          UspInfoRow(
            label: loc(context).internetIPAddress,
            value: wanAddress.isEmpty ? '-' : wanAddress,
          ),
          UspInfoRow(
            label: loc(context).status,
            value: _statusText(context, status),
          ),
          if (showPrivateNote)
            AppText.bodySmall(
              loc(context).ddnsWanAddressPrivate,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }

  /// Re-reads the status now. The address needs no read of its own: the WAN's
  /// push keeps it current.
  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(ddnsStatusDataProvider.notifier).refresh();
    } on ServiceError catch (e) {
      if (mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// The text of each status (implementation doc §9.3 on linksys/FWDEV#191).
  /// A connection failure reads as Failed, as in 1.0; the note under it says
  /// when a private address is why.
  static String _statusText(BuildContext context, DdnsUpdateStatus status) {
    final l = loc(context);
    return switch (status) {
      DdnsUpdateStatus.disabled => l.disabled,
      DdnsUpdateStatus.connecting => l.connecting,
      DdnsUpdateStatus.success => l.success,
      DdnsUpdateStatus.authenticationFailed => l.ddnsAuthenticationFailed,
      DdnsUpdateStatus.invalidHostname => l.invalidHostname,
      DdnsUpdateStatus.settingsIncomplete => l.ddnsSettingsIncomplete,
      DdnsUpdateStatus.connectionFailed => l.failed,
      DdnsUpdateStatus.failed => l.failed,
      DdnsUpdateStatus.unknown => l.unknown,
    };
  }
}
