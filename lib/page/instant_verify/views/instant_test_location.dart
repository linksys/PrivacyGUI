/// Only navigation belongs in the URL: never device IDs, credentials, results,
/// or an instruction to start a monitor or router action.
class InstantTestLocation {
  const InstantTestLocation({this.details, this.flows = const []});
  final int? details;
  final List<int> flows;
  static const _allowedFlows = {1, 2, 3, 4, 5, 6, 30, 31, 32};

  factory InstantTestLocation.parse(String? value) {
    if (value == null || value.isEmpty) return const InstantTestLocation();
    final parts = value.split('/');
    int? details;
    if (parts.first == 'devices' || parts.first == 'network') {
      details = parts.removeAt(0) == 'devices' ? 1 : 2;
    }
    if (parts.length > 8) return const InstantTestLocation();
    final flows = <int>[];
    for (final part in parts) {
      final flow = int.tryParse(part);
      if (!_allowedFlows.contains(flow)) return const InstantTestLocation();
      flows.add(flow!);
    }
    return InstantTestLocation(details: details, flows: flows);
  }

  String get value => [
        if (details != null) details == 1 ? 'devices' : 'network',
        ...flows.map((flow) => '$flow'),
      ].join('/');
}
