part of 'help_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Shared widgets + helpers
// ═══════════════════════════════════════════════════════════════════════════

// Uses the design-system AppCard (same primitive as the dashboardMenu page)
// so border color, surface, and radius exactly match the rest of the app.
Widget _stepCard(BuildContext context, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: Spacing.medium),
      child: SizedBox(width: double.infinity, child: AppCard(
        padding: EdgeInsets.all(ResponsiveLayout.isMobileLayout(context)
            ? Spacing.medium : Spacing.large2),
        child: child,
      )),
    );

Widget _infoBox(BuildContext context, String text,
    {IconData icon = LinksysIcons.infoCircle, Color? color}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18,
            color: color ?? Theme.of(context).colorScheme.primary),
        const AppGap.small2(),
        Expanded(child: AppText.bodyMedium(text)),
      ],
    ),
  );
}

/// Static step item — not interactive. Uses a small dot marker (NOT a
/// triangle/arrow, which reads as expandable/tappable).
Widget _checklistItem(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, left: 4, right: 8),
            child: Icon(LinksysIcons.circle,
                size: 6,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Expanded(child: AppText.bodyMedium(text, selectable: true)),
        ],
      ),
    );

/// Tappable checklist item — customer marks each step as done.
class _ClickChecklistItem extends StatefulWidget {
  final String text;
  const _ClickChecklistItem(this.text);

  @override
  State<_ClickChecklistItem> createState() => _ClickChecklistItemState();
}

class _ClickChecklistItemState extends State<_ClickChecklistItem> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _done = !_done),
      borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _done ? LinksysIcons.checkBox : LinksysIcons.checkBoxOutlineBlank,
              size: 20,
              color: _done
                  ? InstantTestTone.good.color(context)
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const AppGap.small2(),
            Expanded(
              child: AppText.bodyMedium(
                widget.text,
                color: _done
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ISP or Linksys support script — always SelectableText so customer can copy it.
Widget _ispScript(BuildContext context, String script) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InstantTestTone.info.container(context),
        borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium('Say to your provider:',
              color: InstantTestTone.info.onContainer(context)),
          const AppGap.small1(),
          AppText.bodyMedium('"$script"',
              selectable: true,
              color: InstantTestTone.info.onContainer(context)),
        ],
      ),
    );

/// Shared workflow footer, following the page's navigation and check actions.
Widget _linksysSupportTile(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(LinksysIcons.supportAgent,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const AppGap.small2(),
            const AppText.titleSmall('Still need help?'),
          ]),
          const AppGap.small1(),
          AppText.bodySmall(
            'Contact Linksys Support:\nwww.linksys.com/support  •  1-800-326-7114',
            selectable: true,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );

/// Centralised restart confirmation. Shows a dialog, then calls restartRouter().
// Restart confirmation now lives in the shared restart_helper.dart (used by
// all Instant-Test surfaces). Alias kept for the many in-file call sites.
Future<bool> _confirmAndRestart(BuildContext context, WidgetRef ref) =>
    confirmAndRestart(context, ref);

Widget _restartOrEscalate(BuildContext context, WidgetRef ref, InstantVerifyPivotState state) {
  if (state.hasRestartedThisSession) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodySmall(
          'You\'ve already restarted your router this session. '
          'If the issue persists, contact Linksys Support.',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
  return AppOutlinedButton('Restart Router',
                onTap: () => _confirmAndRestart(context, ref),
                icon: LinksysIcons.restartAlt);
}

class _LoadingButton extends StatelessWidget {
  final String label;
  const _LoadingButton({required this.label});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          minimumSize: Size(64, ResponsiveLayout.isMobileLayout(context) ? 48 : 40),
        ),
        onPressed: null,
        icon: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2)),
        label: AppText.labelMedium(label),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// Item 5: Session summary card — shown at ISP escalation screens
// ═══════════════════════════════════════════════════════════════════════════

class _SessionSummaryCard extends ConsumerWidget {
  const _SessionSummaryCard({this.websiteStatus, this.speedStatus});
  // Flow-local checks can be newer than the overview's provider snapshot.
  final String? websiteStatus;
  final String? speedStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantVerifyPivotProvider);
    final scheme = Theme.of(context).colorScheme;

    final rows = <Widget>[];

    if (state.routerModel != null)
      rows.add(_summaryRow(context, 'Router', state.routerModel!));

    if (state.wanStatus != null)
      rows.add(_summaryRow(context, 'WAN', state.wanConnected ? 'Connected' : 'Not connected'));

    if (state.wanIpAddress != null && state.wanIpAddress!.isNotEmpty)
      rows.add(_summaryRow(context, 'WAN IP', state.wanIpAddress!));

    if (websiteStatus != null || state.dnsCheck != null)
      rows.add(_summaryRow(context, 'Websites', websiteStatus ??
          (state.dnsCheck!.resolved ? 'Loading' : 'Not loading')));

    if (speedStatus != null || state.speedTest != null)
      rows.add(_summaryRow(context, 'Speed', speedStatus ??
          '${state.speedTest!.downloadMbps.toStringAsFixed(0)} Mbps down'));

    if (state.routerFirmware != null)
      rows.add(_summaryRow(context, 'Firmware', state.routerFirmware!));

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorSchemeExt.surfaceContainerLow!,
        borderRadius: CustomTheme.of(context).radius.asBorderRadius().medium,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelSmall('What to tell the agent:',
              color: scheme.onSurfaceVariant),
          const AppGap.small1(),
          ...rows,
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(children: [
        SizedBox(
          width: 72,
          child: AppText.bodySmall(label,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Expanded(
          child: AppText.bodySmall(value),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Item 6: Satisfaction prompt — shown at terminal screens
// ═══════════════════════════════════════════════════════════════════════════

class _SatisfactionPrompt extends StatefulWidget {
  const _SatisfactionPrompt();

  @override
  State<_SatisfactionPrompt> createState() => _SatisfactionPromptState();
}

class _SatisfactionPromptState extends State<_SatisfactionPrompt> {
  int? _rating; // 0=fixed, 1=helped, 2=didn't help

  @override
  Widget build(BuildContext context) {
    // Hidden — satisfaction prompts removed until feedback mechanism is defined
    return const SizedBox.shrink();
    // ignore: dead_code
    if (_rating != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AppText.bodySmall(
          _rating == 0
              ? 'Great! Glad that helped.'
              : _rating == 1
                  ? 'Thanks for the feedback.'
                  : 'Sorry about that — contact Linksys Support for more help.',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),
        AppText.labelSmall('Did this help?',
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const AppGap.small1(),
        Row(children: [
          _ratingBtn(context, 0, 'Fixed it', LinksysIcons.checkCircle,
              InstantTestTone.good.color(context)),
          const AppGap.small1(),
          _ratingBtn(context, 1, 'Partly', LinksysIcons.remove,
              InstantTestTone.warning.color(context)),
          const AppGap.small1(),
          _ratingBtn(context, 2, 'Still broken', LinksysIcons.close,
              InstantTestTone.problem.color(context)),
        ]),
      ],
    );
  }

  Widget _ratingBtn(BuildContext context, int rating, String label,
      IconData icon, Color color) {
    return Expanded(
      child: AppOutlinedButton(label,
        icon: icon,
        color: color,
        onTap: () => setState(() => _rating = rating),
      ),
    );
  }
}

