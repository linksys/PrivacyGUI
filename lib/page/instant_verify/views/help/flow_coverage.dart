part of 'help_page.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Flow 4: WiFi doesn't reach a room (unchanged)
// ═══════════════════════════════════════════════════════════════════════════

enum _RouterPlacement { center, corner, enclosed }

class _Flow4 extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  final ValueNotifier<VoidCallback?>? stepBackNotifier;
  final bool singlePage;
  const _Flow4({this.singlePage = false, required this.onDone, this.stepBackNotifier});

  @override
  ConsumerState<_Flow4> createState() => _Flow4State();
}

class _Flow4State extends ConsumerState<_Flow4> {
  int _step = 0;
  _RouterPlacement? _placement;

  void _goToStep1() {
    setState(() => _step = 1);
    widget.stepBackNotifier?.value = () {
      setState(() => _step = 0);
      widget.stepBackNotifier?.value = null;
    };
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.singlePage) ..._singlePage(context)
          else ...[
            if (_step == 0) ..._step0(context),
            if (_step == 1) ..._step1(context),
          ],
        ],
      );

  List<Widget> _singlePage(BuildContext context) {
    final state = ref.watch(instantVerifyPivotProvider);
    final weakNodes = state.meshNodes.where((n) => n.isOnline &&
        (n.backhaulHealth == BackhaulHealth.weak || n.backhaulHealth == BackhaulHealth.critical)).toList();
    return [
      _stepCard(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        UserStepHeading('Improve coverage in that room'),
        const AppGap.small2(),
        if (weakNodes.isNotEmpty)
          for (final node in weakNodes)
            AppText.bodyMedium('${node.name} has a weak connection to the main router. Move it closer to the router, toward the room that needs coverage, or use Ethernet.'),
        if (weakNodes.isEmpty)
          const AppText.bodyMedium('Keep the router or a child node in the open, between the main router and the room with weak WiFi. A node needs a good connection back to the router.'),
        if (state.phase != PivotLoadPhase.complete || state.meshNodes.isEmpty)
          const AppText.bodyMedium('Mesh information is unavailable or incomplete; placement advice is general.'),
      ])),
      ..._step0(context),
      ..._step1(context),
    ];
  }

  List<Widget> _step0(BuildContext context) {
    final options = [
      (_RouterPlacement.center, 'Center of my home or close to it'),
      (_RouterPlacement.corner, 'Near a wall, door, or in a corner'),
      (_RouterPlacement.enclosed, 'Inside a closet, cabinet, or behind the TV'),
    ];
    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserStepHeading('Where is your router right now?'),
          const AppGap.small3(),
          for (final (val, label) in options)
            RadioListTile<_RouterPlacement>(
              value: val,
              groupValue: _placement,
              title: AppText.bodyMedium(label),
              onChanged: (v) => setState(() => _placement = v),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          const AppGap.small3(),
          if (!widget.singlePage) Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Continue',
                onTap: _placement == null ? null : _goToStep1),
          ),
        ],
      )),
    ];
  }

  List<Widget> _step1(BuildContext context) {
    String advice = switch (_placement) {
      _RouterPlacement.enclosed =>
        'Move your router out into the open. Enclosures block WiFi signals significantly — even a shelf in the open can double your range.',
      _RouterPlacement.corner =>
        'Move your router toward the center of your home — halfway between the router and the room with weak signal.',
      _RouterPlacement.center =>
        'Central placement can help. Building materials (concrete, brick, or metal studs) can still weaken the signal.',
      null => 'Choose your current placement above for a tailored tip. Keep the router elevated and in the open.',
    };

    return [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.titleSmall('Placement tip'),
          const AppGap.small2(),
          AppText.bodyMedium(advice, selectable: true),
        ],
      )),
      DetailsDisclosure(label: 'More coverage tips', child: Column(children: [
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.titleSmall('Quick tips'),
          const AppGap.small2(),
          _tipRow(context, LinksysIcons.check, 'Keep your router elevated — on a shelf or table, not the floor'),
          _tipRow(context, LinksysIcons.check, 'Point antennas vertically if your router has them'),
          _tipRow(context, LinksysIcons.check, 'Keep it away from microwaves, baby monitors, and cordless phones'),
          _tipRow(context, LinksysIcons.close, 'Don\'t put it inside a cabinet, closet, or entertainment unit'),
        ],
      )),
      _stepCard(context,
          _infoBox(
            context,
            'If you live in an apartment building or dense area, interference from neighboring WiFi networks can cause weak signal — even with perfect placement.',
          )),
      _stepCard(context, Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.titleSmall('Need more coverage?'),
          const AppGap.small2(),
          const AppText.bodyMedium(
            'Adding a Linksys child node in that room extends your WiFi coverage using the same network name and password — your devices connect automatically.',
            selectable: true,
          ),
        ],
      )),
      ])),
      Align(
              alignment: Alignment.centerLeft,
              child: AppFilledButton('Done',
                onTap: widget.onDone),
      ),
      const _SatisfactionPrompt(),

    ];
  }

  Widget _tipRow(BuildContext context, IconData icon, String text) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 18,
                color: (icon == LinksysIcons.check
                        ? InstantTestTone.good
                        : InstantTestTone.problem)
                    .color(context)),
            const AppGap.small2(),
            Expanded(child: AppText.bodyMedium(text, selectable: true)),
          ],
        ),
      );
}

