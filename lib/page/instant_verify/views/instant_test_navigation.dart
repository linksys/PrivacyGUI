import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_test_device_id_provider.dart';
import 'package:privacy_gui/route/constants.dart';

/// Route names of the Instant-Test pages. The local preview registers the
/// same pages under its own names and overrides [instantTestRoutesProvider].
class InstantTestRoutes {
  const InstantTestRoutes({
    required this.home,
    required this.devices,
    required this.network,
    required this.help,
  });

  final String home;
  final String devices;
  final String network;
  final String help;
}

final instantTestRoutesProvider = Provider<InstantTestRoutes>(
  (ref) => const InstantTestRoutes(
    home: RouteNamed.menuInstantTest,
    devices: RouteNamed.instantTestDevices,
    network: RouteNamed.instantTestNetwork,
    help: RouteNamed.instantTestHelp,
  ),
);

/// Opens one help flow. The device, if any, is handed over like
/// deviceDetailIdProvider: set first, then push.
void pushInstantTestHelp(BuildContext context, WidgetRef ref, int flow,
    {DiagnosticClient? device}) {
  ref.read(instantTestDeviceIdProvider.notifier).state =
      device?.macAddress ?? '';
  context.pushNamed(ref.read(instantTestRoutesProvider).help,
      queryParameters: {'flow': '$flow'});
}

void pushInstantTestDevices(BuildContext context, WidgetRef ref) =>
    context.pushNamed(ref.read(instantTestRoutesProvider).devices);

void pushInstantTestNetwork(BuildContext context, WidgetRef ref) =>
    context.pushNamed(ref.read(instantTestRoutesProvider).network);

/// Leaves the help flows, back to the page that opened the first one.
void popInstantTestHelp(BuildContext context, WidgetRef ref) {
  final help = ref.read(instantTestRoutesProvider).help;
  Navigator.of(context).popUntil((route) => route.settings.name != help || route.isFirst);
}

/// Returns to the Instant-Test home page.
void popToInstantTestHome(BuildContext context, WidgetRef ref) {
  final home = ref.read(instantTestRoutesProvider).home;
  Navigator.of(context)
      .popUntil((route) => route.settings.name == home || route.isFirst);
}
