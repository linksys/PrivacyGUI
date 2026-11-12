import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/nav_tap_guard.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/administration/providers/upnp_data_provider.dart';
import 'package:privacy_gui/page/firewall/models/firewall_card_summary.dart';
import 'package:privacy_gui/page/firewall/models/firewall_verdict.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The dashboard's Firewall card (#1130): what the internet can reach.
///
/// Each row is one settings page and shows that page's main value, under the
/// page's own name; tapping it opens the page. `(i)` says what the setting
/// means and what changing it does, and only shows while the row lets
/// something in. The rows are the card's only links: it has no "View details",
/// because no one page is its detail. Three rows always, plus at most one
/// warning row, so the card
/// never grows with the number of rules. Which rows show and what they count
/// is [FirewallCardSummary]'s.
///
/// Three forms, by width: the full card from the spec's `normalAbove` (272px,
/// the narrowest at which every row reads in every locale); the compact form
/// down to `kPopupBelow`, without `(i)` and the flag column, and cutting what
/// still does not fit with an ellipsis that reveals it on hover; and
/// below that the popup form, which shows the badge.
///
/// What it replaced, and why: the rule count over the router's internal chain
/// ("11/25"), its Accept / Drop donut, the protocol chart and the Ports tab.
/// The total counted rules no page shows, and "enabled" means opposite things
/// for an Accept rule and a Drop rule, so neither number could be read.
class UspFirewallOverviewCard extends ConsumerWidget {
  const UspFirewallOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firewall = ref.watch(firewallDataProvider).valueOrNull;
    if (firewall == null) return const CardSkeleton.list(rows: 3);
    final summary = FirewallCardSummary.of(
      firewall: firewall,
      forwardingRules:
          ref.watch(portForwardingDataProvider).valueOrNull?.ruleModels,
      triggeringRules:
          ref.watch(portTriggeringDataProvider).valueOrNull?.ruleModels,
      upnpEnabled: ref.watch(upnpDataProvider).valueOrNull,
    );
    final verdict = _verdictLabel(context, summary.verdict);

    return DashboardCardTemplate(
      title: loc(context).firewallOverview,
      trailing: AppBadge(
        label: verdict,
        color: _verdictColor(context, summary.verdict),
      ),
      popupValue: verdict,
      // No "View details": the rows open four different pages, so no one page
      // is the card's detail. The rows are its only way out (#1130).
      content: _Rows(summary: summary),
    );
  }

  static String _verdictLabel(BuildContext context, FirewallVerdict verdict) =>
      switch (verdict) {
        FirewallVerdict.protected => loc(context).firewallVerdictProtected,
        FirewallVerdict.basic => loc(context).firewallVerdictBasic,
        FirewallVerdict.dmzActive => loc(context).firewallVerdictDmzActive,
        FirewallVerdict.atRisk => loc(context).firewallVerdictAtRisk,
      };

  static Color? _verdictColor(BuildContext context, FirewallVerdict verdict) {
    final colors = Theme.of(context).extension<AppColorScheme>();
    return switch (verdict) {
      FirewallVerdict.protected => colors?.semanticSuccess,
      FirewallVerdict.basic => colors?.semanticInfo,
      FirewallVerdict.dmzActive => colors?.semanticWarning,
      FirewallVerdict.atRisk => colors?.semanticDanger,
    };
  }
}

/// Shown for a value that has not been read yet, or failed to read.
const String _kUnknown = '—';

class _Rows extends StatelessWidget {
  const _Rows({required this.summary});

  final FirewallCardSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = loc(context);
    final s = summary;
    final spiOff = s.spiOff;
    final portRules = s.portRules;
    final upnpOn = s.upnpOn;
    final compact = CardDensityScope.of(context) == CardDensity.compact;
    // A flagged row leads with its flag, and the other rows keep their labels
    // in line with it. Not in the compact form, which needs the width.
    final indent = !compact && (spiOff != null || s.dmzOn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.nothingOpen) ...[
          Padding(
            padding: BlockConstants.paddingListItem,
            child: Row(
              children: [
                Expanded(
                  child: AppText.bodyMedium(l.firewallCardNothingOpen),
                ),
                if (!compact) ...[
                  AppGap.xs(),
                  _InfoIcon(l.firewallCardNothingOpenInfo),
                ],
              ],
            ),
          ),
          AppGap.xs(),
        ],
        if (spiOff != null) ...[
          _PageRow(
            compact: compact,
            identifier: 'firewall-card-spi',
            flagged: true,
            indent: indent,
            label: l.firewallCardSpiFirewall,
            value: switch (spiOff) {
              SpiOff.ipv4 => l.firewallCardSpiIpv4Off,
              SpiOff.ipv6 => l.firewallCardSpiIpv6Off,
              SpiOff.both => l.firewallCardSpiBothOff,
            },
            info: l.firewallCardSpiInfo,
            navigate: (router) => router.pushNamed(RouteNamed.uspFirewall),
          ),
          // Set apart by space rather than a divider: the row is a block of its
          // own already, and a divider's height is what pushed the tallest
          // state past three rows (#1130). `xs` on top of the row's own `xs`,
          // because the template's footer placeholder, which the card has with
          // no detail link, leaves `ko` no room for `sm`.
          AppGap.xs(),
        ],
        _PageRow(
          compact: compact,
          identifier: 'firewall-card-dmz',
          flagged: s.dmzOn,
          indent: indent,
          label: l.dmz,
          value: !s.dmzOn
              ? l.off
              : s.dmzHost.isEmpty
                  ? l.on
                  : l.firewallCardDmzOnHost(s.dmzHost),
          info: s.dmzOn ? l.firewallCardDmzInfo : null,
          navigate: (router) => router.pushNamed(RouteNamed.uspDmz),
        ),
        _PageRow(
          compact: compact,
          identifier: 'firewall-card-port-forwarding',
          indent: indent,
          label: l.portForwarding,
          value: switch (portRules) {
            null => _kUnknown,
            (:final on, :final total) when on == total =>
              l.firewallCardPortRules(total),
            (:final on, :final total) =>
              l.firewallCardPortRulesOnOfTotal(on, total),
          },
          info: (portRules?.on ?? 0) > 0
              ? l.firewallCardPortForwardingInfo
              : null,
          navigate: (router) =>
              router.pushNamed(RouteNamed.uspPortForwardingDetail),
        ),
        _PageRow(
          compact: compact,
          identifier: 'firewall-card-upnp',
          indent: indent,
          label: l.upnp,
          value: switch (upnpOn) {
            null => _kUnknown,
            true => l.on,
            false => l.off,
          },
          info: upnpOn == true ? l.firewallCardUpnpInfo : null,
          navigate: (router) => router.pushNamed(RouteNamed.uspAdministration),
        ),
      ],
    );
  }
}

/// One settings page: its name over its main value, `(i)` while it lets
/// something in, and a chevron to the page.
///
/// Two lines, not one. A label, a value, `(i)` and a chevron side by side need
/// more than the card has at its narrowest widths: at 288px — the narrowest the
/// grid gives the card's preferred span — "IPv4 and IPv6 off" lost its second
/// half and a DMZ host given by MAC broke across lines, with nothing reported as
/// an overflow (#1130). The value on a line of its own gets the row's whole text
/// column.
///
/// Built on [LayoutBlock] rather than [SettingBlock] or [NavLinkBlock], which
/// each have half of it: [SettingBlock] the label over the value but no leading
/// flag, chevron or double-tap guard; [NavLinkBlock] the guard and the chevron
/// but a description rather than a value, and no `(i)`. Neither carries the
/// semantics boundary a row inside a dashboard card needs, since both were built
/// for settings pages.
class _PageRow extends StatelessWidget {
  const _PageRow({
    required this.identifier,
    required this.label,
    required this.value,
    required this.info,
    required this.navigate,
    required this.indent,
    required this.compact,
    this.flagged = false,
  });

  /// The row's E2E hook. Spelled as a literal at each call site, which is what
  /// the identifier generator harvests.
  final String identifier;
  final String label;
  final String value;
  final String? info;

  /// Opens the row's page. The `pushNamed` stays spelled at each call site,
  /// with its literal route, which is what the navigation invariants scan.
  final void Function(GoRouter router) navigate;

  /// Leads with a warning flag.
  final bool flagged;

  /// Keeps the label in line with a flagged row's.
  final bool indent;

  /// The compact form: no `(i)`, the flag before the label instead of in a
  /// column of its own, and the label and the value one line each. What does
  /// not fit is cut with an ellipsis that reveals the whole text on hover or
  /// long-press.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>();
    final colorScheme = Theme.of(context).colorScheme;
    // Cut with an ellipsis that reveals the whole value on hover or
    // long-press. The full form allows two lines and never reaches the cut: its
    // floor is where the widest value, a DMZ host by MAC, fits. The compact form
    // allows one, because two do not help it: a MAC is one unbreakable token,
    // and given two lines Flutter breaks it mid-token (`AA:BB:CC:D` / `D:EE:FF`)
    // and reports nothing clipped, so no tooltip would show.
    final valueText = AppOverflowText(
      value,
      variant: AppTextVariant.labelLarge,
      maxLines: compact ? 1 : 2,
    );
    // Every row opens a page, so every row ends in a chevron, compact included.
    final chevron = AppIcon.font(
      Icons.chevron_right,
      size: BlockConstants.iconMd,
      color: colorScheme.onSurfaceVariant,
    );
    Widget flag(double size) => AppIcon.font(
          Icons.error_outline,
          size: size,
          color: colors?.semanticWarning ?? colorScheme.error,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      // Swallow the second tap of a double-tap so the page is pushed once per
      // gesture (#1445), and close the presentation first when this is the
      // presented copy of the card (#1453).
      child: NavTapGuard(
        onTap: () => navigateFromCard(context, navigate),
        // A boundary of its own, or the grid item's semantics node absorbs the
        // row's tap and the whole card navigates (#1301) — the reason
        // [cardDetailLink] has one.
        builder: (context, guardedTap) => Semantics(
          container: true,
          button: true,
          identifier: identifier,
          child: LayoutBlock(
            onTap: guardedTap,
            padding: BlockConstants.paddingListItem,
            child: compact
                ? Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (flagged) ...[
                                  flag(BlockConstants.iconSm),
                                  AppGap.xs(),
                                ],
                                // One line, cut with an ellipsis that reveals
                                // the whole label on hover or long-press: a
                                // long single word ("Portvidarebefordran")
                                // would otherwise break mid-word.
                                Expanded(child: AppOverflowText(label)),
                              ],
                            ),
                            valueText,
                          ],
                        ),
                      ),
                      AppGap.xs(),
                      chevron,
                    ],
                  )
                : Row(
                    children: [
                      if (flagged)
                        flag(BlockConstants.iconMd)
                      else if (indent)
                        const SizedBox(width: BlockConstants.iconMd),
                      if (flagged || indent) AppGap.sm(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.bodyMedium(label),
                            valueText,
                          ],
                        ),
                      ),
                      if (info != null) ...[
                        AppGap.xs(),
                        _InfoIcon(info!),
                      ],
                      AppGap.xs(),
                      chevron,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// `(i)`: what a setting means and what changing it does. Opens on tap as well
/// as on hover, so it works on touch.
class _InfoIcon extends StatelessWidget {
  const _InfoIcon(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => AppTooltip(
        message: message,
        child: AppIcon.font(
          Icons.info_outline,
          size: BlockConstants.iconSm,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}
