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

  /// The router's own error code, when this notification carried `cmd_failure`
  /// instead of output arguments.
  ///
  /// This is the **only** channel a refusal arrives on. An Operate *response* is
  /// not one: measured, a command that does not exist and a misspelled argument
  /// name both answer `UspSuccess`, so a caller that reads its result out of the
  /// data model — a firmware check re-reading `FirmwareImage.{ota}.Available`,
  /// say — has to watch here to tell "the router looked and found nothing" from
  /// "the router would not look".
  ///
  /// Null on every ordinary completion, including a failed *diagnostic*: those
  /// report their failure in [status] because the command itself ran.
  final String? errorCode;

  /// The router's message for [errorCode], empty-string-normalised away to null.
  final String? errorMessage;

  /// Whether the notification carried a `cmd_failure` member **at all**.
  ///
  /// Deliberately not the same question as [errorCode] being non-null, and the
  /// difference is the one misparse that matters here. A refusal is identified by
  /// the presence of `cmd_failure`; [errorCode] is only what the router chose to
  /// put *inside* it, read under two spellings because the bridge hands some
  /// payloads through with protobuf's camelCase intact. Keying "was this refused"
  /// off a successful read of one optional member meant a third spelling — or a
  /// refusal the router named with a message and no code — read as a **success**,
  /// on the one channel a refusal ever arrives on.
  ///
  /// Defaults to inferring from [errorCode] so that a hand-built result (a test,
  /// a fake) still reads as a refusal when it names a code. Only the SSE parser
  /// passes it explicitly, because only the parser saw the member.
  final bool refused;

  const OperateResult({
    required this.commandName,
    required this.commandKey,
    required this.status,
    required this.outputArgs,
    this.errorCode,
    this.errorMessage,
    bool? refused,
  }) : refused = refused ?? errorCode != null;

  bool get isComplete => status == 'Complete';
  bool get isError => status == 'Error';

  /// Whether the command completed and reported no output arguments at all.
  ///
  /// USP's third OperationComplete outcome, and the one that has no `status` of
  /// its own to be read from: a notification carrying **neither** `output_args`
  /// nor `cmd_failure` is a success that produced nothing. #1579 fixed [status]
  /// reporting that case as `'Unknown'` — indistinguishable from "no status was
  /// reported" — and this getter is the other half of the fix: a caller that has
  /// to tell "completed and told us nothing" from "completed and told us
  /// something" asks here rather than inferring it from an empty map.
  ///
  /// Derived rather than stored, because the two possible inputs answer the same
  /// question. The spec says a no-output success carries no `output_args` member,
  /// and a member present but empty means the same thing to every caller.
  bool get completedWithoutOutput => !refused && outputArgs.isEmpty;

  /// Whether the router refused the command outright.
  ///
  /// Keyed on [refused] rather than on [status], because the two answer
  /// different questions: `status == 'Error'` is a diagnostic that ran and
  /// failed, which is a *result*. This is the absence of a result.
  bool get isFailure => refused;

  @override
  String toString() => 'OperateResult($commandName, status=$status, '
      'args=${outputArgs.length} params'
      '${errorCode != null ? ', failure=$errorCode $errorMessage' : ''})';
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

/// Parsed NSLookup result from [OperateResult.outputArgs].
///
/// Output args typically include:
/// - Status: "Success", "Error_DNSServerNotResolved", "Error_HostNameNotResolved", etc.
/// - SuccessCount: number of successful results
/// - Result.{i}.Status, Result.{i}.HostNameReturned, Result.{i}.IPAddresses,
///   Result.{i}.DNSServerIP, Result.{i}.ResponseTime, Result.{i}.AnswerType
class NsLookupResult {
  final String hostName;
  final String status;
  final int successCount;
  final List<NsLookupAnswer> answers;

  const NsLookupResult({
    required this.hostName,
    required this.status,
    required this.successCount,
    required this.answers,
  });

  bool get isComplete => status == 'Complete' || status == 'Success';
  bool get hasAnswers => answers.any((a) => a.ipAddresses.isNotEmpty);

  factory NsLookupResult.fromOperateResult(
      OperateResult result, String hostName) {
    final args = result.outputArgs;

    final answerMap = <int, Map<String, String>>{};
    for (final entry in args.entries) {
      final match = RegExp(r'Result\.(\d+)\.(\w+)').firstMatch(entry.key);
      if (match != null) {
        final idx = int.parse(match.group(1)!);
        final field = match.group(2)!;
        answerMap.putIfAbsent(idx, () => {});
        answerMap[idx]![field] = entry.value;
      }
    }

    final answers = answerMap.entries.map((e) {
      final f = e.value;
      return NsLookupAnswer(
        index: e.key,
        status: f['Status'] ?? '',
        answerType: f['AnswerType'] ?? '',
        hostNameReturned: f['HostNameReturned'] ?? '',
        ipAddresses: (f['IPAddresses'] ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        dnsServerIp: f['DNSServerIP'] ?? '',
        responseTimeMs: int.tryParse(f['ResponseTime'] ?? '') ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return NsLookupResult(
      hostName: hostName,
      status: args['Status'] ?? result.status,
      successCount: int.tryParse(args['SuccessCount'] ?? '') ?? 0,
      answers: answers,
    );
  }
}

/// A single answer entry in an NSLookup result.
class NsLookupAnswer {
  final int index;
  final String status;
  final String answerType;
  final String hostNameReturned;
  final List<String> ipAddresses;
  final String dnsServerIp;
  final int responseTimeMs;

  const NsLookupAnswer({
    required this.index,
    required this.status,
    required this.answerType,
    required this.hostNameReturned,
    required this.ipAddresses,
    required this.dnsServerIp,
    required this.responseTimeMs,
  });

  bool get isOk => status == 'Success' && ipAddresses.isNotEmpty;
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
