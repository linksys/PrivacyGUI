/// Provider overrides for `router_assistant_view` (#1380, wave 4).
///
/// One provider, and the reason it needs overriding at all is a timer rather than
/// a layout. `initState` finds no environment credentials (see
/// [gateRouterAssistantHasNoStoredCredentials] for why that is deterministic in a
/// test), so it sets `_isRestoring = true` and awaits
/// `AwsCredentialsStore.readWithin(5s)`. Left real, that call reaches
/// `FlutterSecureStorage` — a `MethodChannel` with no handler in a widget test —
/// through a `Future.timeout`, so every one of the 234 cells would pump a failing
/// platform call and the form would be measured in its sealed `readOnly` state
/// for however long the failure took to land. Pinning the store makes the restore
/// resolve inside the first frame and the cell one deterministic layout.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ai_assistant/services/aws_credentials_store.dart';

/// An [AwsCredentialsStore] that answers immediately and writes nothing.
///
/// `Fake` rather than a real store over an in-memory map because the class the
/// view depends on is the *reads*, and the real one wraps every read in
/// `_serialize` + `Future.timeout` — machinery whose whole purpose is ordering
/// across a platform channel this fixture does not have. Anything the view does
/// not call throws through `noSuchMethod`, which is the point: a future edit that
/// reaches for `store()` or `clear()` from a layout path fails loudly here rather
/// than silently succeeding against a fixture that pretended to persist.
class FixedAwsCredentialsStore extends Fake implements AwsCredentialsStore {
  FixedAwsCredentialsStore(this._stored);

  final StoredAwsCredentials? _stored;

  @override
  Future<StoredAwsCredentials?> readWithin(Duration within) async => _stored;

  /// Reached from the model dropdown's `onChanged`, which no cell taps — kept
  /// only so a dropdown selection in a future readability test is not a crash.
  @override
  Future<void> storeModelId(String modelId) async {}
}

/// Overrides for `router_assistant_view`.
List<Override> routerAssistantOverrides({
  StoredAwsCredentials? stored = gateRouterAssistantHasNoStoredCredentials,
}) =>
    [
      awsCredentialsStoreProvider
          .overrideWithValue(FixedAwsCredentialsStore(stored)),
    ];

/// Nothing saved, which is the state the config screen exists for.
///
/// Null rather than a record because a record connects: `_restoreSavedCredentials`
/// builds a `RouterChatController` from it and the view swaps to the chat screen,
/// whose first act is an AWS Bedrock call. So the config screen is not one of two
/// states this fixture could choose between — it is the only one a test can hold
/// still, and it is also the one a user without `assets/agents/.env` sees.
///
/// Why that file being absent is deterministic here and not merely usual: the view
/// reads `AWSConfig.fromEnvironment()`, which reads `dotenv.env`, and `dotenv` is
/// initialised by an explicit `dotenv.load()` in `main.dart` that no widget test
/// runs. So `dotenv` throws `NotInitializedError` in the gate whether or not a
/// developer happens to have the gitignored `.env` on disk, and `_needsConfig` is
/// true for every cell on every machine. The `requires` premise on
/// `kRouterAssistantPageCase` is what would catch that reasoning going stale.
const StoredAwsCredentials? gateRouterAssistantHasNoStoredCredentials = null;
