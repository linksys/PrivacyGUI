/// Result of an async USP Operate command delivered via SSE OperationComplete.
///
/// The payload comes directly from the SSE notification — NOT from a GET
/// request. This is critical because BUG-006 means Operate results are NOT
/// written back to the TR-181 data model.
class OperateResult {
  /// The operate command name (e.g., "IPPing()", "TraceRoute()").
  final String commandName;

  /// UUID correlator from the operate request.
  final String commandKey;

  /// Operation status: "Complete", "Error", etc.
  final String status;

  /// Full output arguments from the Operate response.
  final Map<String, String> outputArgs;

  const OperateResult({
    required this.commandName,
    required this.commandKey,
    required this.status,
    required this.outputArgs,
  });

  bool get isComplete => status == 'Complete';
  bool get isError => status == 'Error';

  @override
  String toString() => 'OperateResult($commandName, status=$status, '
      'args=${outputArgs.length} params)';
}

/// Parsed Ping result from [OperateResult.outputArgs].
class PingResult {
  final String host;
  final int successCount;
  final int failureCount;
  final int avgResponseTime;
  final int minResponseTime;
  final int maxResponseTime;
  final String status;

  const PingResult({
    required this.host,
    required this.successCount,
    required this.failureCount,
    required this.avgResponseTime,
    required this.minResponseTime,
    required this.maxResponseTime,
    required this.status,
  });

  bool get isComplete => status == 'Complete';
  int get totalCount => successCount + failureCount;
  double get successRate =>
      totalCount > 0 ? successCount / totalCount * 100 : 0;

  factory PingResult.fromOperateResult(OperateResult result, String host) {
    final args = result.outputArgs;
    return PingResult(
      host: host,
      successCount: int.tryParse(args['SuccessCount'] ?? '') ?? 0,
      failureCount: int.tryParse(args['FailureCount'] ?? '') ?? 0,
      avgResponseTime: int.tryParse(args['AverageResponseTime'] ?? '') ?? 0,
      minResponseTime: int.tryParse(args['MinimumResponseTime'] ?? '') ?? 0,
      maxResponseTime: int.tryParse(args['MaximumResponseTime'] ?? '') ?? 0,
      status: result.status,
    );
  }
}

/// A single hop in a traceroute result.
class TracerouteHop {
  final int hopNumber;
  final String host;
  final String hostAddress;
  final List<int> rtTimes;

  const TracerouteHop({
    required this.hopNumber,
    required this.host,
    required this.hostAddress,
    required this.rtTimes,
  });

  int get avgRoundTrip => rtTimes.isNotEmpty
      ? (rtTimes.reduce((a, b) => a + b) / rtTimes.length).round()
      : 0;
}

/// Parsed Traceroute result from [OperateResult.outputArgs].
class TracerouteResult {
  final String host;
  final String status;
  final List<TracerouteHop> hops;

  const TracerouteResult({
    required this.host,
    required this.status,
    required this.hops,
  });

  bool get isComplete => status == 'Complete';

  factory TracerouteResult.fromOperateResult(
      OperateResult result, String host) {
    final args = result.outputArgs;

    // Parse RouteHops.{i}.Host, RouteHops.{i}.HostAddress, RouteHops.{i}.RTTimes
    final hopMap = <int, Map<String, String>>{};
    for (final entry in args.entries) {
      final match = RegExp(r'RouteHops\.(\d+)\.(\w+)').firstMatch(entry.key);
      if (match != null) {
        final hopNum = int.parse(match.group(1)!);
        final field = match.group(2)!;
        hopMap.putIfAbsent(hopNum, () => {});
        hopMap[hopNum]![field] = entry.value;
      }
    }

    final hops = hopMap.entries.map((e) {
      final fields = e.value;
      final rtTimesStr = fields['RTTimes'] ?? '';
      final rtTimes = rtTimesStr.isNotEmpty
          ? rtTimesStr
              .split(',')
              .map((s) => int.tryParse(s.trim()) ?? 0)
              .toList()
          : <int>[];
      return TracerouteHop(
        hopNumber: e.key,
        host: fields['Host'] ?? '',
        hostAddress: fields['HostAddress'] ?? '',
        rtTimes: rtTimes,
      );
    }).toList()
      ..sort((a, b) => a.hopNumber.compareTo(b.hopNumber));

    return TracerouteResult(
      host: host,
      status: result.status,
      hops: hops,
    );
  }
}
