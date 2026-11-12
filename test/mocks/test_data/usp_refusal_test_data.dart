import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_refusal_reason.dart';

import 'usp_envelope_test_data.dart';

/// A Set the router refused, as the WASM client resolves it (it never throws
/// on a refusal).
///
/// The shape is the bench's (FLWRT 2.0.3.26100921, 2026-10-12,
/// `Device.NAT.PortMapping`, the app's client, `allowPartial: false`): every
/// leaf of the Set comes back under code 7012; the refused leaf's message
/// starts with the firmware's error name, and each of [otherLeaves] says only
/// that the group failed at the refused leaf. The refused leaf is listed after
/// [otherLeaves], since the bench showed it need not come first.
///
/// Measured again on 2.0.4.26103108 (2026-11-09) on all four tables the pages
/// write — `NAT.PortMapping`, `NAT.PortTrigger`, the IPv6 rules under
/// `Firewall.Chain` and `Firewall.DMZ` — with the same shape on each, and no
/// refusal arriving as transport 9999. The router lists the leaves in the
/// order they were written, the refused one wherever it falls; nothing reads
/// that order, so the refused leaf is put last here.
///
/// Each leaf is a `kind: parameter` entry: the router answered the Set with
/// an `OperationSuccess` whose instance took no parameter and carries every
/// one in `param_errs`, which usp-client 0.16.0 reports as `success: false`
/// and one `parameter` entry per leaf (`usp-client/src/wasm/mod.rs`).
Map<String, dynamic> refusedSetEnvelope({
  required String instancePath,
  required String refusedLeaf,
  required String message,
  List<String> otherLeaves = const [],
}) =>
    UspEnvelopeTestData.parameterErrors(
      {
        for (final leaf in otherLeaves)
          '$instancePath$leaf': (
            code: 7012,
            message: "SetParameterGroup: group set failed at "
                "'$instancePath$refusedLeaf' (Invalid value)",
          ),
        '$instancePath$refusedLeaf': (code: 7012, message: message),
      },
      success: false,
    );

/// A [ServiceError] whose failures carry [reason]: what a page's save throws
/// once the USP layer has read the router's refusal.
Matcher carriesRefusalReason(UspRefusalReason reason) =>
    isA<ServiceError>().having(
        (e) => switch (e) {
              UspCompleteFailureError(:final failures) ||
              UspPartialFailureError(:final failures) =>
                failures.map((f) => f.refusalReason).toList(),
              _ => const <UspRefusalReason>[],
            },
        'refusal reasons',
        contains(reason));
