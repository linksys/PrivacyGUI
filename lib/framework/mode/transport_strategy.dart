import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/framework/mode/bridge_config.dart';

/// **Cause 1 — how bytes reach the router.**
///
/// Local: `browser → router`. Remote Assistance: `browser → Guardian → router`.
/// Everything that differs *because the path differs* belongs here: which
/// endpoint table is in force, which host, which bearer token, and how SSE
/// subscriptions have to be driven over that path.
///
/// See `doc/mode_strategy/mode_strategy_guide.md` and the design doc in the
/// first comment of #1474. Rule 3: this contract lives in `lib/framework/mode/`,
/// its implementations in `lib/core/mode/impl/`.
abstract class TransportStrategy {
  /// The [BridgeConfig] this mode's [UspBridgeClient] must be built from, or
  /// `null` when the mode cannot describe a transport yet.
  ///
  /// Null is not an error state: in Remote Assistance the mode is known at
  /// startup from `ForceCommand`, but the session — hence the host, the token
  /// and the session-scoped endpoint paths — arrives only after the agent
  /// validates a `?session=&token=` link. `LocalTransportStrategy` never
  /// returns null.
  ///
  /// Takes a [Ref] because the remote answer is *reactive*: it reads the
  /// Guardian session config out of `remoteAssistanceProvider`, and the watch
  /// is what makes a re-`activate()` rebuild the bridge. Do not convert this
  /// into a plain getter — see the guide's "the select is load-bearing" note.
  BridgeConfig? bridgeConfig(Ref ref);

  /// The SSE subscription discipline for this transport.
  ///
  /// Reached *through* the transport rather than selected by its own `if`,
  /// because "which subscription dance" is a consequence of "which path" — the
  /// Guardian proxy rejects duplicate subscription IDs and scopes them to the
  /// stream; the on-router bridge is idempotent. This is the one mode contract
  /// that predates #1474; it is not rewritten, only re-homed.
  SseOperationStrategy sseStrategy(UspBridgeClient bridge);

  /// Whether the router answers over *this* path right now.
  ///
  /// The reachability half of the recovery probe, and a mode cause because the
  /// question is not the same question in both modes. Locally it is "is the
  /// on-router bridge up and is its agent ready" — `GET /health` and two fields
  /// of its body. Remotely it is Guardian's own `/usp/health` for the session,
  /// which answers for the device on the far side of the proxy rather than for a
  /// local agent, so success means something different (#1576). The two share a
  /// path shape and nothing else, which is why this is a question and not a URL.
  ///
  /// **Never throws.** A probe that threw would have to be wrapped by every
  /// caller, and the two implementations disagree about what a throw even means
  /// — a 504 from the bridge and a rejected fetch through Guardian arrive as
  /// different exception types. Returning `false` puts that judgement where the
  /// path is known. `RecoveryProbeService` relies on this: it has no try/catch
  /// around this call.
  Future<bool> isRouterReachable(Ref ref);
}
