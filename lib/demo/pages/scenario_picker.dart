/// Scenario picker for demo (showcase) mode.
///
/// A small icon button (top-right) opens a dialog listing the UI-state
/// scenarios (populated / empty / disabled / wan-static / …). Each scenario is
/// a declarative override fetched from `data/scenario-<name>.json` — the SAME
/// override files the E2E suite drives — so the demo showcases exactly the
/// states E2E asserts.
///
/// This is the ONLY intentional demo-vs-production UI difference: a tiny,
/// unobtrusive affordance. Selecting a scenario reflects it in the `?scenario=`
/// URL query (shareable) and reloads so every provider re-reads the derived
/// data. The dialog is always centered on-screen, so options are never clipped
/// (unlike a bottom-anchored dropdown).
library;

import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/core/utils/assign_ip/assign_ip.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/demo/usp/demo_usp_data_loader.dart';

/// Scenario names must match the E2E `data/scenario-<name>.json` files
/// (exported from the E2E SCENARIOS table). 'populated' = clean base.
const List<String> kDemoScenarios = [
  'populated',
  'empty-devices',
  'empty-port-forwarding',
  'wifi-disabled',
  'wifi-empty',
  'wan-no-internet',
  'wan-static',
  'firewall-spi-off',
  'dmz-enabled',
  'dhcp-off',
];

class ScenarioPicker extends StatelessWidget {
  const ScenarioPicker({super.key});

  static String get _current {
    final q = Uri.base.queryParameters['scenario'];
    return (q != null && kDemoScenarios.contains(q)) ? q : 'populated';
  }

  Future<void> _openPicker() async {
    // This widget lives in MaterialApp.router's builder — a sibling of the
    // Navigator, so its own context has no Navigator/Overlay ancestor. Use the
    // router's navigator context (which does) to host the dialog.
    final navContext = routerKey.currentContext;
    if (navContext == null) return;
    final selected = await showAppDialog<String>(
      context: navContext,
      builder: (ctx) => _ScenarioDialog(current: _current),
    );
    if (selected == null || selected == _current) return;

    // Reflect the choice in the URL (shareable) and reload so all providers
    // re-read the freshly-derived data. Pre-apply so a non-reloading host still
    // updates the in-memory store.
    await DemoUspDataLoader.instance.applyScenario(selected);
    final base = Uri.base;
    final next = base.replace(queryParameters: {
      ...base.queryParameters,
      'scenario': selected,
    });
    assignWebLocation(next.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _current != 'populated';
    return Material(
      color: Colors.transparent,
      child: IconButton(
        // No `tooltip`: this button sits outside the Navigator/Overlay (it's in
        // MaterialApp.router's builder), and RawTooltip needs an Overlay
        // ancestor. The icon colour signals whether a scenario is active.
        icon: Icon(
          Icons.tune,
          size: 20,
          color: isCustom ? Colors.orange.shade700 : Colors.blueGrey.shade400,
        ),
        onPressed: _openPicker,
      ),
    );
  }
}

/// Dialog body: a radio list of scenarios; returns the chosen name via pop.
class _ScenarioDialog extends StatefulWidget {
  const _ScenarioDialog({required this.current});

  final String current;

  @override
  State<_ScenarioDialog> createState() => _ScenarioDialogState();
}

class _ScenarioDialogState extends State<_ScenarioDialog> {
  late String _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      titleText: 'Demo scenario',
      semanticLabel: 'demo-scenario-picker',
      scrollable: true,
      content: SizedBox(
        width: 320,
        child: AppRadioList<String>(
          selected: _selected,
          items: [
            for (final name in kDemoScenarios)
              AppRadioListItem<String>(title: name, value: name),
          ],
          onChanged: (_, value) {
            if (value != null) setState(() => _selected = value);
          },
        ),
      ),
      actions: [
        AppButton.text(
          label: 'Cancel',
          onTap: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: 'Apply',
          onTap: () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}
