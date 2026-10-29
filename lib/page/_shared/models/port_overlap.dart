/// The port-range and protocol comparisons FWDEV#204's overlap checks share:
/// port forwarding and triggering (`port_rule_limits.dart`) and IPv6 port
/// services (`ipv6_port_service_ui_model.dart`) collide the same way.
library;

/// Closed ranges overlap when either end lies in the other. TR-181 writes a
/// single port as an end of 0 (or as an end equal to the start); both read as
/// `[start, start]`.
bool portRangesOverlap(int aStart, int aEnd, int bStart, int bEnd) =>
    aStart <= _rangeEnd(bStart, bEnd) && bStart <= _rangeEnd(aStart, aEnd);

/// Whether two protocols share TCP or UDP: `Both` is TCP and UDP, so it
/// shares a protocol with either.
bool protocolsShare(String a, String b) =>
    _protocols(a).intersection(_protocols(b)).isNotEmpty;

Set<String> _protocols(String protocol) =>
    protocol == 'Both' ? const {'TCP', 'UDP'} : {protocol};

int _rangeEnd(int start, int end) => end > start ? end : start;
