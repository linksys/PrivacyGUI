import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/statistics/views/components/stats_section_card.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Radio channel info + per-band client distribution donut.
class StatsWifiChannelsSection extends ConsumerWidget {
  const StatsWifiChannelsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifiData = ref.watch(wifiDataProvider).valueOrNull;
    if (wifiData == null) {
      return StatsSectionCard(
        title: loc(context).wifiChannels,
        subtitle: loc(context).wifiChannelsSubtitle,
        chartHeight: 320,
        child: Center(
          child: AppText.bodyMedium(
            loc(context).loading,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final radios = wifiData.radioModels;
    final activeClients = _buildClientList(wifiData);

    return StatsSectionCard(
      title: loc(context).wifiChannels,
      subtitle: loc(context).wifiChannelsSubtitle,
      chartHeight: 320,
      // The 320px box scrolls (#1297). With the donut gone this section is a
      // column of per-radio text blocks and nothing else, so it shrink-wraps and
      // *can* scroll — and it has to, because its height is set by data and
      // locale rather than by the box: a block costs 52px on one run and 72px on
      // two, and the localized channel prefix takes a second run in all 26
      // locales at the 288px production floor. 5 radios need 360px there and 6
      // need 432px of a fixed 320px box; before this, the excess was painted
      // outside the card. See `CardScrollRegion` for why the fixed height stays.
      scrollable: true,
      child: radios.isEmpty
          ? Center(
              child: AppText.bodyMedium(
                loc(context).noWifiRadiosAvailable,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : _buildChart(context, radios, activeClients),
    );
  }

  List<_ClientInfo> _buildClientList(WifiData wifiData) {
    final clients = <_ClientInfo>[];
    for (final entry in wifiData.wifiClientMap.entries) {
      final client = entry.value;
      if (!client.active) continue;
      final detail = wifiData.connectionDetailMap[entry.key];
      clients.add(_ClientInfo(client: client, band: detail?.band ?? ''));
    }
    return clients;
  }

  Widget _buildChart(BuildContext context, List<WifiRadioUIModel> radios,
      List<_ClientInfo> clients) {
    final colorScheme = Theme.of(context).colorScheme;

    // Group clients by radio. Shared with the WiFi Performance card's Channels
    // tab since #1271: this file had its own copy of the loop without the
    // `noise == 0` guard, so the same clients averaged to a *lower* SNR here
    // than there. One implementation is what keeps the two surfaces equal.
    final stats = aggregateRadioClientStats(
      bands: [for (final radio in radios) radio.band],
      clients: [
        for (final c in clients)
          (
            band: c.band,
            signalStrength: c.client.signalStrength,
            noise: c.client.noise,
          ),
      ],
    );

    return Column(
      children: [
        // Per-radio info rows
        ...List.generate(radios.length, (i) {
          final radio = radios[i];
          final clientCount = stats.clientCount(i);
          // `null` when no client on this radio reported a noise floor — a
          // distinct state from 0 dB, and rendered as one below (#1271).
          final snr = stats.averageSnr(i);

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              // `stretch`, not `start`, and it is load-bearing for the `Wrap`
              // below. `start` hands children a *loose* width constraint, so a
              // `Wrap` shrink-wraps to its intrinsic width and
              // `WrapAlignment.spaceBetween` has no free space to distribute —
              // it silently degrades to `spacing` and the whole block sits
              // centred in the section instead of spanning it. `stretch` makes
              // the width tight, which is what the pre-#1258 `Row` + `Spacer`
              // had, so `spaceBetween` reproduces the `Spacer` exactly.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Band + channel string.
                //
                // DEGRADATION SHAPE (#1258, the third instance of the #1226 /
                // #1252 shape on this page) — design §2.10, §2.10a:
                //
                //  1. A `Wrap`, not a `Row` + `Spacer`. While the content fits it
                //     renders exactly as before: one run, `spaceBetween` puts the
                //     band left and the channel string right, which is what the
                //     `Spacer` did — but only because the `Column` above
                //     stretches it. Under a loose width `spaceBetween` is a
                //     no-op; see the `crossAxisAlignment` note there. When it
                //     does not fit the channel string drops to a second line
                //     instead of overflowing. That is not hypothetical any more:
                //     the localized prefix below spent the 47px of headroom
                //     #1258 measured, and a 3-digit 6GHz channel is still to
                //     come.
                //  2. Neither side yields to an ellipsis: the band is the
                //     identity of the block and the channel string is composed
                //     data (§2.10a point 2). Both are content, not chrome, so
                //     they keep their intrinsic width and the row wraps as a
                //     unit — an ellipsis mid-channel-string misinforms.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    // Band + its client count as **one** `Wrap` child, in the
                    // same shape as the Wi-Fi Performance twin (#1267, #1297):
                    // the count belongs to this radio, so it reads beside the
                    // band rather than on a line of its own, and keeping the
                    // two in a `Row` preserves the two-child `spaceBetween`
                    // measured below — a third top-level child would have the
                    // alignment distribute slack *between* band and count too.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText.labelLarge(radio.band),
                        AppGap.xs(),
                        // Icon + numeral, not "N clients", as on the dashboard.
                        // #1297 first kept the sentence on the line below on a
                        // headroom argument — the count+SNR pair measured
                        // 112.0-166.2px of a 238px content box, so it fitted —
                        // and fitting is not the same as being worth the width.
                        // The word names what the whole Devices tab is about and
                        // it repeats on every radio; compressed, the count costs
                        // 23.2px (14px glyph + `xxs` + numeral) against the
                        // sentence's 36.3px (`id`) to 90.5px (`fi`).
                        //
                        // What it does not do is come for free, and the honest
                        // reading is the opposite of the one above: moving it
                        // *here* adds 27.2px to this row (`xs` + 23.2px), which
                        // takes the band row from one run to two in all 26 locales
                        // at the 288px floor (it was 3 of 26 — `th` 257.3, `ja`
                        // 240.8, `en` 239.0 against 238px), so a block costs 72px
                        // there instead of 52px. That height is paid for by the
                        // scroll region this section now has, not avoided — see
                        // `scrollable: true` above.
                        //
                        // The string stays in the semantics tree, so a screen
                        // reader still hears "3 clients" and E2E still locates
                        // the count by it: this is a visual compression, not a
                        // dropped label.
                        Semantics(
                          label: loc(context).clientsCount(clientCount),
                          excludeSemantics: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // `devices`, not `genericDevice`: the latter is an
                              // abstract four-square glyph that reads as "grid"
                              // at 14px, while this one is the phone-plus-laptop
                              // pictogram the rest of the app uses for clients.
                              AppIcon.font(
                                AppFontIcons.devices,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              AppGap.xxs(),
                              AppText.bodySmall(
                                '$clientCount',
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Localized prefix (#1270), in the same form as the Wi-Fi
                    // Performance `_ChannelsTab` twin (#1266). It spends the
                    // 47px of headroom #1258 measured, and the `Wrap` above is
                    // what makes it affordable. Measured against the pre-#1264
                    // `Row` + `Spacer` with this same string, and re-taken for
                    // #1298: `th` +3.0 at a 288px section (the production
                    // floor), 15 of 26 locales overflowing at 256px and all 26
                    // at 224 / 192px — `th` worst at +99.0/+85.0. Under the
                    // `Wrap` all 26 are clean at all four widths.
                    //
                    // The widest `channel` value is `th`'s at 188.4px. It was
                    // `tr`'s at 212.5px until #1298: the ARB shipped
                    // `'Channel (Kanal)'`, the English term with the Turkish
                    // glossed in parentheses, which also overflowed the floor
                    // here (+27.0/+13.0) under the pre-fix shape. Either value
                    // wraps to a second line rather than overflowing, so this
                    // was never a live defect on this row — but it is why the
                    // row's guard walks all 26 locales rather than a sample
                    // (`stats_wifi_channels_section_test.dart`, AC-1 ladder).
                    AppText.bodySmall(
                      '${loc(context).channel} ${radio.channelDisplay}'
                      '  \u00b7  ${radio.channelBandwidth}',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                AppGap.xs(),
                // The SNR, alone on its line, and both of the things that used
                // to share it are gone (#1297) — the same two removals the
                // dashboard twin made in #1267, on the same measurements.
                //
                //  1. The 96px linear `AppLoader` that followed the number could
                //     not be read. `normalizeSNR` is `(snr / 50).clamp(0, 1)` —
                //     1.92px of a 96px bar per dB, with no tick, no scale and no
                //     unit — and it saturates: 50, 55, 60 and 70 dB all paint the
                //     identical full bar. Beside the number it encodes, it
                //     restated it more coarsely above 50 dB and not at all.
                //     It also cost a run: at 96px + `AppSpacing.sm` it claimed
                //     104px of the 238px content width at the 288px production
                //     floor, leaving 134px for a stats pair that measured
                //     140-167px in 7 of the 26 locales (`fi` 166.2, `ja` 157.9,
                //     `ko` 152.6, `vi` 146.4, `ru` 140.6, `zh`/`zh_TW` 140.5), so
                //     in those it took its own run and the block grew 8-9px out
                //     of a *fixed* 320px chart box.
                //  2. The client count moved up beside the band, which is where
                //     it belongs, and that is what lets this be a plain `AppText`
                //     rather than the `Wrap` the interim revision needed. A lone
                //     text has no sibling to collide with, so there is no #1258
                //     cliff to wrap away from: a long translation of "SNR" wraps
                //     inside its own paragraph. The pair that used to sit here
                //     overflowed a 216.2px section in `fi` even under `Row(min)`;
                //     alone, the widest reading of the 26 (`zh`/`zh_TW`
                //     `snrValue`, 69.8px; `snrUnavailable` is 41.4px everywhere)
                //     clears the 238px content box with 168px to spare.
                //
                // #1271's unknown-SNR state is untouched: with no reading the
                // readout is still `snrUnavailable`, never `0 dB`. What went away
                // is the branch that had to keep a bar from being drawn at zero
                // for it — there is no bar to suppress.
                AppText.bodySmall(snr == null
                    ? loc(context).snrUnavailable
                    : loc(context).snrValue(snr.toInt())),
              ],
            ),
          );
        }),
        // Where the band-distribution donut used to be (#1297).
        //
        // It plotted clients-per-band — one slice per radio, sized by that
        // radio's client count, with the total in the hole. The dashboard twin
        // deleted the same chart in #1267 for being a second rendering of what
        // the blocks above it already print; on this surface it was the *third*,
        // because `StatsDeviceDistributionSection` — the first card of this same
        // Devices tab — draws the band distribution as labelled horizontal bars,
        // band name and count included.
        //
        // It was also broken in two ways this file's own suite could not see:
        //
        //  - **Its labels never fit.** `AppPieChart` prints each slice title
        //    *on* the slice, and at `size: 120` the themed `pieCenterRadius` (60)
        //    is capped to a 45px hole, leaving a **15px** ring. The titles are
        //    40px (`5GHz`, `6GHz`) to 60px (`2.4GHz`) wide, so every one of them
        //    straddled the ring onto the card background — white-on-pale and
        //    unreadable — at *every* width, 841px as much as 288px, and up to
        //    18.5px past the 120px box for a skewed split. There is no width at
        //    which a 60px word fits a 15px ring, which is why this was a removal
        //    and not a resize.
        //  - **It painted over the rows.** The chart sat in an `Expanded` inside
        //    a fixed 320px box, and `AppPieChart` derives its geometry from the
        //    `size` it is given rather than the box it gets. Measured slot
        //    heights in `en`: 188px at 2 radios, 136px at 3, **84px at 4**, 32px
        //    at 5, 0px at 6 (288px section). From 4 radios the 120px drawing was
        //    larger than its slot, so at 5 it painted across the last radio's SNR
        //    and at 6 it drew a full circle straddling the card's bottom edge
        //    while `probeSectionOverflow` reported **nothing at all** — the same
        //    silent overpaint #1267 measured on the dashboard.
        //
        // What would earn this space is data the section does not already state —
        // airtime utilization or same-channel neighbours — which is #1295, and
        // deferred. Until then the per-radio rows are the record.
      ],
    );
  }
}

class _ClientInfo {
  final WifiClientUIModel client;
  final String band;
  const _ClientInfo({required this.client, this.band = ''});
}
