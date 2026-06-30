# Error Handling Implementation Guide (USP Feature)

> **This document answers "how to do it".** When adding a USP feature page, what pattern should error handling follow, what should be displayed, what should not be displayed, and how to achieve localization.
> **Background knowledge ("why")** — how errors flow from firmware up to the UI, the differences between 9999/7xxx/9xxx/9998, and the causes of the two paths — see [`usp-error-handling-reference.md`](usp-error-handling-reference.md). This document only references it when needed and does not restate it.
> **Source of the existing approach**: PR #953 (`feat(l10n): centralize error message localization for USP features`). All code examples in this document match the current codebase, not an idealized plan.

---

## 0. One-Minute Overview (TL;DR)

Errors flow up a single line, **with fixed responsibilities at each layer**:

```
Service  →  catch any error, convert to typed ServiceError, then throw
            (fetch: map directly; save: self-throw Usp*FailureError first, then let the guard pass it through)
   │  ServiceError object
   ▼
Provider →  pass through only, no processing, no BuildContext, no string conversion
            fetch: store ServiceError into state.error (or let it flow into AsyncValue.error)
            save : rethrow
   │  ServiceError object
   ▼
View     →  the only place that does localization
            receive ServiceError → localizeServiceError(context, error) → localized string
            fetch failure: empty-state widget; save failure: snackbar
```

**Three iron rules**:
1. **Service is the error conversion point**: what flows up is always a `ServiceError`, not a raw string, not an `Exception`.
2. **Provider only passes through the type**: never `'$e'` flattened into a string (once the type is lost, the View cannot localize).
3. **Only the View does localization**: through the single central mapper `localizeServiceError()`. Service/Provider have no `BuildContext`, nor should they.

---

## 1. Service Layer: Convert All Errors to ServiceError

The Service is the error "convergence point". Whether the underlying layer throws a string, an envelope, or a Dart exception, when it leaves the Service it is **always a `ServiceError`**.

fetch and save are **two different patterns**, differing only by one guard.

### 1.1 fetch (GET) — no guard

Reference: [`usp_dmz_service.dart`](../../lib/page/dmz/services/usp_dmz_service.dart) `fetch()`

```dart
Future<(DmzSettings, DmzStatus)> fetch() async {
  try {
    final dmzData = await Dmz.fetch(_usp);   // codegen / WASM failure → throws raw string
    final uiModel = buildUIModel(dmzData);   // pure data assembly, never throws ServiceError
    return (DmzSettings(model: uiModel, ...), const DmzStatus(isLoading: false));
  } catch (e) {
    throw mapUspErrorToServiceError(e);      // map directly, no guard needed
  }
}
```

**Why no guard is needed**: in fetch's try block, the only things thrown are codegen / WASM raw strings, plus pure data assembly (which does not throw ServiceError). The `e` received by `catch` cannot be a ServiceError, so no check is necessary.

### 1.2 save (SET / ADD / DELETE) — has the `is ServiceError` guard

Reference: [`usp_dmz_service.dart`](../../lib/page/dmz/services/usp_dmz_service.dart) `update()` / `add()`

```dart
Future<void> update({required String instancePath, required DmzUIModel model}) async {
  try {
    final result = await Dmz.update(_usp, [DmzEntryUpdate(...)]);
    switch (UspResultParser.parseSetResult(result)) {
      case UspSuccess():
        break;
      case UspPartialSuccess(:final errorSummary, :final successes, :final failures):
        throw UspPartialFailureError(            // ← Service itself throws a ServiceError
          summary: 'DMZ update partial failure: $errorSummary',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,                    // full List<UspErrorDetail>, do not store only path
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(           // ← same as above
          summary: 'DMZ update failed: $errorSummary',
          failures: errors,
        );
    }
  } catch (e) {
    if (e is ServiceError) rethrow;              // guard: pass self-thrown ServiceError through as-is
    throw mapUspErrorToServiceError(e);          // only the remaining raw strings get mapped
  }
}
```

**Why the guard is needed**: save parses the batch envelope and **actively `throw UspPartialFailureError` / `UspCompleteFailureError` (already ServiceError)**. Without the guard, these self-thrown ServiceErrors would be caught by the outer catch and then passed into `mapUspErrorToServiceError`, where, not matching the `"{Op} failed:"` format, they would be mis-wrapped as `UnexpectedError`, losing all semantics. The guard lets "the ServiceError you threw yourself bubble up as-is".

> **In one sentence**: the guard = the indicator of "whether the try block self-throws a ServiceError". If yes (save) → guard needed; if no (fetch) → not needed.

### 1.3 batch failures must always store the full `failures`

`UspPartialFailureError` / `UspCompleteFailureError` are **containers** holding `List<UspErrorDetail> failures` (full path + errorCode + errorMessage).

- ✅ **Store the entire `failures` list** (pass it directly from the `failures`/`errors` of `UspPartialSuccess`/`UspFailure`).
- ❌ **Do not store only the path string** — that loses the errorCode, and the View cannot localize by code.
- `failedPaths` is a derived getter (`failures.map((f) => f.requestedPath)`), backward-compatible; you don't need to assemble it yourself.

### 1.4 Do not hardcode "user-facing" error messages in the Service

The Service has no `BuildContext`, so it **should not assemble any copy meant for the user to see**.
- The `summary` field is an English summary **for log / debug use**; it is never shown to the user (the View does not read it).
- The only "text" that flows from the Service to the UI is `UnexpectedError.detail` (the View displays it as a fallback) — but that is a diagnostic string, not UI copy you hardcoded.

> ⚠ **field-level form validation is a separate line**, do not confuse it. The `Map<String,String>` returned by `validateForm()` (e.g. `{'destIp': 'Invalid IP address'}`) is field-level validation that goes through `status.fieldErrors`, **not a ServiceError**. Its localization belongs to the general form string scope and is not part of this document's error handling pipeline.

---

## 2. Provider Layer: Pass Through Only, No Processing

The Provider's only responsibility is to **pass the `ServiceError` given by the Service up untouched**. No `BuildContext`, no string conversion, no copy assembly, no further calls to `mapUspErrorToServiceError`.

There are two forms depending on the page architecture.

### 2.1 Preservable / Notifier pages (state.error)

Reference: [`usp_dmz_notifier.dart`](../../lib/page/dmz/providers/usp_dmz_notifier.dart)

**fetch failure → store into `state.error` (typed, not a string)**:

```dart
@override
Future<(DmzSettings?, DmzStatus?)> performFetch({...}) async {
  try {
    final (settings, status) = await _svc.fetch();
    return (settings, status);
  } on ServiceError catch (e) {                 // always catch the ServiceError type
    logger.e('[USP][...][DMZ]: Fetch failed', error: e);
    return (null, DmzStatus(isLoading: false, error: e));  // store the object, not '$e'
  }
}
```

**save failure → rethrow** (the framework's `save()` is transparent and does not catch, letting the ServiceError pass straight through to the View):
the save path does not need its own catch; `PreservableAutoDisposeNotifierMixin.save()` lets the ServiceError thrown by the Service propagate up directly.

The corresponding state model:

```dart
class DmzStatus extends Equatable {
  /// Typed error from the last fetch. View localizes it via localizeServiceError.
  final ServiceError? error;            // ✅ not String? errorMessage

  DmzStatus copyWith({
    ServiceError? error,
    bool clearError = false,            // ← see the pitfall below
    ...
  }) => DmzStatus(
        error: clearError ? null : (error ?? this.error),
        ...
      );
}
```

> ⚠ **Pitfall: clearing the error in `copyWith` must use the `clearError` flag**. Dart's `error ?? this.error` cannot distinguish "not passed" from "passed null", so clearing the error state (e.g. before a re-fetch) must go through the explicit `clearError: true`, and cannot rely on passing `error: null`.

### 2.2 AsyncNotifier pages (AsyncValue.error)

Reference: [`usp_admin_notifier.dart`](../../lib/page/admin/providers/usp_admin_notifier.dart)

These pages use `AsyncNotifier`, letting the error flow directly into `AsyncValue.error`:

```dart
class UspAdminNotifier extends AutoDisposeAsyncNotifier<UspAdminState> {
  @override
  Future<UspAdminState> build() async {
    try {
      final adminUser = await _svc.fetchAdmin();
      return UspAdminState(...);
    } on ServiceError catch (e) {
      logger.e(...);
      rethrow;                          // rethrow → into AsyncValue.error, View catches it with .when(error:)
    }
  }
}
```

> **How to choose**: follow the page's existing state architecture; do not change the architecture for the sake of error handling.
> - Pages using `FeatureState` / `Preservable` → 2.1 (state.error).
> - Pages using `AsyncNotifier` → 2.2 (AsyncValue.error).
> Both render fetch failures with the same `ServiceErrorView` in the View (see §3.1); only "where the error is stored" and "how retry is triggered" differ.

---

## 3. View Layer: The Only Place That Does Localization

The View receives the `ServiceError` and passes it to the central mapper [`localizeServiceError(context, error)`](../../lib/components/localizations/service_error_localizations.dart) to get the localized string. **This is the only place in the entire codebase that turns an error type into a display string.**

### 3.1 Displaying fetch failures → always `ServiceErrorView`

Both page architectures render fetch failures with the **same** shared widget
[`ServiceErrorView`](../../lib/components/views/service_error_view.dart). Only two things
differ between them: where the error comes from, and how retry is triggered.

`ServiceErrorView` already calls `localizeServiceError` internally; you don't translate it
yourself. It shows: an error icon + the `loc(ctx).failedToLoadSettings` title + the
localized detail + a retry button (and an optional secondary action — see below).

**(A) state.error pages** — pass `status.error` directly (it is already a `ServiceError?`):

```dart
if (status.error != null) {
  return ServiceErrorView(
    error: status.error,
    onRetry: () => ref.read(uspDmzProvider.notifier).fetch(forceRemote: true),
  );
}
```

**(B) AsyncValue pages** — inside `.when(error:)`, the callback hands you an `Object error`,
so narrow it with `error is ServiceError ? error : null`; retry re-runs `build()` via
`ref.invalidate`:

```dart
asyncState.when(
  loading: () => const Center(child: AppLoader()),
  error: (error, stack) => ServiceErrorView(
    error: error is ServiceError ? error : null,
    onRetry: () => ref.invalidate(uspAdminProvider),
  ),
  data: (state) => _buildContent(context, ref, state),
);
```

> **Why the narrow?** `ServiceErrorView.error` is `ServiceError?`, but `AsyncValue.when(error:)`
> gives `Object`. `ServiceErrorView` accepts `null` (it then shows just the generic title), so
> a non-ServiceError degrades safely. (One known case: the `apps` page fetches lighttpd static
> JSON and throws plain `Exception`, not `ServiceError` — it deliberately keeps its own error
> widget instead of `ServiceErrorView`. See §7.)

**Optional secondary action.** When a page needs an escape hatch (e.g. the dashboard's
"Log out" when it cannot load at all), pass `secondaryLabel` + `onSecondary`:

```dart
ServiceErrorView(
  error: error is ServiceError ? error : null,
  onRetry: () => ref.read(dashboardOrchestratorProvider.notifier).refreshAll(),
  secondaryLabel: loc(context).logout,
  onSecondary: () => _logout(context, ref),
);
```

### 3.2 Displaying save failures → snackbar

Reference: [`usp_dmz_view.dart`](../../lib/page/dmz/views/usp_dmz_view.dart) `_onSave`

The common form is **try/catch wrapping `notifier.save()`**:

```dart
Future<void> _onSave(BuildContext context, WidgetRef ref) async {
  try {
    await doSomethingWithSpinner(context, ref.read(uspDmzProvider.notifier).save());
    if (context.mounted) {
      showSuccessSnackBar(context, loc(context).dmzSettingsSaved);
    }
  } catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));  // ← localize
    }
  }
}
```

- ✅ `showFailedSnackBar(context, localizeServiceError(context, e))`
- ❌ `showFailedSnackBar(context, 'Failed to save: $e')` (flattening the string directly, not localized)

`showFailedSnackBar` / `showSuccessSnackBar` have the signature `(BuildContext, String)` — they take an already-translated string and are not responsible for translation.

> **The point is "the string always goes through `localizeServiceError`"; which snackbar API you use is secondary.** Most pages use the shared `showFailedSnackBar` (recommended); a few pages (such as [`instant_privacy_view.dart`](../../lib/page/instant_privacy/views/instant_privacy_view.dart)) directly use `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizeServiceError(context, e))))`. Both are correct — the key invariant: **the displayed string comes from `localizeServiceError`, not raw `'$e'`**.

### 3.3 dashboard card mutation → use the shared helper `performUspMutation`

The inline action buttons on a dashboard card (network status, WiFi, port forwarding…) — such as "renew lease" or "add reservation" — do **not** write their own try/catch, but call the shared helper [`performUspMutation`](../../lib/page/_shared/components/usp_mutation_helper.dart). It wraps "set loading state → run mutation → success/failure snackbar" into a single entry point:

```dart
// Reference: the "renew lease" button in usp_network_status_card.dart
onTap: () => performUspMutation(
  context,
  ref,
  loadingKey: 'wanRenew',                                   // corresponds to uspMutationLoadingProvider
  mutation: () => ref.read(uspInternetSettingsProvider.notifier).renewDhcpLease(),
  successMessage: loc(context).xxx,                         // pass an "already loc()'d string"
),
```

**This is not a "third localization strategy" — it is just a convenience entry point for the card to trigger a mutation.** On failure the helper already calls `localizeServiceError` internally, so:

- ✅ **You don't need to localize the failure message yourself** — just pass `mutation`, and the helper will localize the thrown `ServiceError` before displaying it.
- ⚠ **`successMessage` is displayed as-is** (the helper does not translate it) — so **the caller must pass an already-`loc()`'d string**, not hardcoded English.
- Applicable scenario: a single inline action on a dashboard card (not a full-page form save). A full-page form save still goes through the view try/catch in §3.2.

> This helper is the encapsulation, in the card scenario, of the "Service → Provider → View" main line in §0: inside the mutation it still passes through the Service (throws ServiceError) → Provider (rethrow) → the helper's catch (`localizeServiceError`).

---

## 4. What to Display / What Not to Display

This is the most important principle in this document. Error information serves two purposes, **always kept separate**:

| | For the user (UI) | For the engineer (log/debug) |
|---|---|---|
| Content | a single l10n sentence determined by the **ServiceError type** | `code` (fault code), `detail` (firmware original text / WASM technical string) |
| How it arrives | `localizeServiceError(context, error)` | `logger.e(..., error: e)`, `'$e'` (toString) |
| Localization | ✅ always (26 locales) | ❌ not localized (firmware English technical string, untranslatable) |

**Rules**:
1. **The message shown in the UI is determined by the type**, not the `detail` / `code`. The user sees "this setting could not be found", not `'Unexpected error: ...(code: 7026)'`.
2. **`detail` / `code` go only into the log**. They are diagnostic raw material, firmware English technical strings; shown to the user they are neither understandable nor localizable.
3. **The only exception: `UnexpectedError`**. It is the fallback, with no type semantics, so `localizeServiceError` displays its `detail` (if any), otherwise falling back to `errorUnexpected`. This is a deliberate compromise — an unmapped error gives at least some clue.

### 4.1 What the central mapper looks like (`localizeServiceError`)

```dart
String localizeServiceError(BuildContext context, Object error) {
  final l = loc(context);
  if (error is! ServiceError) return l.errorUnexpected;   // defensive
  return switch (error) {
    NotAuthenticatedError()      => l.errorNotAuthenticated,
    InvalidCredentialsError()    => l.errorInvalidCredentials,
    SessionTokenExpiredError()   => l.errorSessionExpired,
    InvalidSessionTokenError()   => l.errorInvalidSessionToken,
    UnauthorizedError()          => l.errorUnauthorized,
    ResourceNotFoundError()      => l.errorResourceNotFound,
    InvalidInputError()          => l.errorInvalidInput,
    NetworkError()               => l.errorNetwork,
    ConnectivityError()          => l.errorConnectivity,
    TimeoutError()               => l.errorTimeout,
    ServiceNotInitializedError() => l.errorServiceNotReady,
    // batch: display the specific error of the first entry (see §4.2)
    UspPartialFailureError(:final failures)  => _localizeBatch(context, failures),
    UspCompleteFailureError(:final failures) => _localizeBatch(context, failures),
    // fallback: the only type that displays detail
    UnexpectedError(:final detail) => detail ?? l.errorUnexpected,
    StorageError()               => l.errorUnexpected,   // never reaches UI (intercepted at session/auth layer)
    SerialNumberMismatchError()  => l.errorUnexpected,   // same as above
  };
}
```

The `switch` is **exhaustive** over the sealed `ServiceError` — this is a design point: when a subclass is added, the compiler warns that a case is missing here, **forcing you to add the l10n**, so nothing is missed.

### 4.2 batch errors: display the specific message of the first entry

`Usp*FailureError` holds multiple `failures`. **Strategy: always display the specific error of `failures.first`** (translated into the corresponding l10n sentence by its `errorCode`).

- ❌ Do not use "N settings failed" — vague, and the user has no way to fix it.
- ✅ Display the specific error of the first entry; if there is still a second entry after the user fixes it, the next save will display the next one — still traceable.

```dart
String _localizeFaultCode(BuildContext context, int code) => switch (code) {
  7004 || 7005 || 7006 || 9008 => loc(context).errorInvalidInput,
  7026 || 7027 || 9005 || 9007 => loc(context).errorResourceNotFound,
  9001                         => loc(context).errorUnauthorized,
  9999                         => loc(context).errorNetwork,
  _                            => loc(context).errorUnexpected,   // unknown vendor code does not leak the original text
};
```

---

## 5. Achieving Localization

1. **Framework**: the project uses `flutter_localizations` (`loc(context).xxx`), **not slang**. (Migrating to slang was evaluated once; because the "translation without context" need was measured at 0 in practice and the migration cost was high, the ROI was negative → keep the status quo. All error copy is translated in the View layer with context.)
2. **ARB key**: the key for error messages is in `lib/l10n/app_en.arb`, named `errorXxx` (camelCase). The existing 12 generic keys:
   ```
   errorNotAuthenticated, errorInvalidCredentials, errorSessionExpired,
   errorInvalidSessionToken, errorUnauthorized, errorResourceNotFound,
   errorInvalidInput, errorNetwork, errorConnectivity, errorTimeout,
   errorServiceNotReady, errorUnexpected
   ```
   Plus the shared: `failedToLoadSettings`, `retry`.
3. **Multi-language**: after adding the English key to `app_en.arb`, also add translations for the other 25 locales (`app_es.arb` / `app_ja.arb` …).

**In most cases you don't need to add an error key** — the existing 12 types already cover common errors. You only need to when adding a ServiceError subclass (see §6).

---

## 6. Adding a ServiceError Subclass (Rare)

Only do this when none of the existing types can express a certain error semantic. Steps:

1. In [`service_error.dart`](../../lib/core/errors/service_error.dart) add `final class XxxError extends ServiceError`, with `{super.code, super.detail}`.
2. **Compile**: the `switch` in `localizeServiceError` will immediately warn that a case is missing (sealed enforcement).
3. In `app_en.arb` add the corresponding `errorXxx` key (+ translations for the other locales).
4. In the `switch` add `XxxError() => l.errorXxx`.
5. At the appropriate place in the Service layer `throw XxxError(...)`, or add the mapping in `mapUspErrorToServiceError`.

> ⚠ Before adding, think it through: do you "really need a new type" or is "an existing type + a different l10n sentence" enough? A type is for "the whole app treating it consistently", not for customizing copy for a single page.

---

## 7. Important Notes and Pitfalls (Do & Don't)

| Do ✅ | Don't ❌ |
|---|---|
| Service `catch → throw mapUspErrorToServiceError(e)` (fetch) | Service throws a raw string / `Exception` up |
| Service save uses the `if (e is ServiceError) rethrow` guard | save misses the guard → the self-thrown ServiceError is mis-wrapped as UnexpectedError |
| batch stores the full `failures` list | stores only the `failedPaths` string (errorCode lost) |
| Provider fetch stores `state.error = e` (typed) | Provider `errorMessage: '$e'` (type lost, cannot localize) |
| `copyWith` clears error with `clearError: true` | passing `error: null` to clear it (eaten by `?? this.error`, not cleared) |
| View always `localizeServiceError(context, e)` | View hardcodes `'Failed to save: $e'` / `'Unable to load X'` |
| `detail`/`code` go only into `logger.e(..., error: e)` | showing `detail`/`code` to the user (firmware English technical string) |
| follow the page's existing state architecture to choose §3.1 (A) or (B) | change the page architecture for the sake of error handling |

### Known Limitations

- **GET 9999→9998 bug (unfixed)**: a GET connection failure (9999, which should be "network error") is disguised as 9998 at the transport layer's 5th layer → ultimately localized as "input error" (`errorInvalidInput`). This is a transport layer bug, independent of localization. Until it is fixed, **a GET failure's "input error" message may actually be a connection issue**. For the root cause see [`usp-error-handling-reference.md`](usp-error-handling-reference.md) §2.5.
- **`_localizeFaultCode` and `_mapProtocolError` must stay in sync**: the fetch path (string → `_mapProtocolError` in `mapUspErrorToServiceError`) and the save batch path (envelope → `_localizeFaultCode` in `localizeServiceError`) must give consistent results for the same firmware code. Change one and the other must change too. `_localizeFaultCode`'s doc comment already states "Mirrors `_mapProtocolError` … MUST stay in sync"; the reverse direction (the `usp_error.dart` side) currently **has no** back-pointing reminder, so when changing `_mapProtocolError` you must remember to go back and sync `_localizeFaultCode` yourself.

### Out of This Pipeline's Scope

- **firmware_update**: has a lot of flow copy, with its own exception + state-driven error display; a separate scope.
- **SSE subscription errors**: a separate error path (server push), does not go through this pipeline.
- **instant_setup (pnp_* wizard)**: still uses its own `errorMessage` + `ref.listen` display, not incorporated.
- **apps page**: fetches lighttpd static JSON (not USP/TR-181) and throws plain `Exception`, not `ServiceError`. It deliberately keeps its own error widget (showing a localized `unableToLoadApps`, not the raw exception) rather than `ServiceErrorView`.
- **field-level form validation**: `validateForm`'s `Map<String,String>` goes through `fieldErrors`, not ServiceError (see §1.4).

---

## 8. Pre-PR Checklist

- [ ] Service fetch `catch → throw mapUspErrorToServiceError(e)`; save has the `is ServiceError` guard.
- [ ] batch failure stores the full `failures` list (not only the path).
- [ ] state model uses `ServiceError? error`, not `String? errorMessage`; `copyWith` has `clearError`.
- [ ] Provider has no `'$e'` / `errorMessage: '...'`; fetch stores the type, save rethrows.
- [ ] View's fetch failure renders `ServiceErrorView` (state.error pages pass `status.error`; AsyncValue pages pass `error is ServiceError ? error : null` inside `.when(error:)`).
- [ ] View's save failure goes through `showFailedSnackBar(context, localizeServiceError(context, e))`.
- [ ] dashboard card inline actions use `performUspMutation` (it already localizes failures automatically), with `successMessage` passing an already-`loc()`'d string.
- [ ] No hardcoded English error strings (`'Unable to load...'`, `'Failed to save: $e'`, `'Error: $e'`).
- [ ] If adding a ServiceError subclass: add the ARB key (including the other locales) + the `switch` case.
- [ ] `flutter analyze` has no warnings (especially the sealed switch's exhaustiveness).

---

## Appendix: Key Files

| File | Role |
|---|---|
| [`lib/core/errors/service_error.dart`](../../lib/core/errors/service_error.dart) | sealed `ServiceError` type definition |
| [`lib/core/usp/errors/usp_error.dart`](../../lib/core/usp/errors/usp_error.dart) | `mapUspErrorToServiceError` (string → ServiceError) |
| [`lib/components/localizations/service_error_localizations.dart`](../../lib/components/localizations/service_error_localizations.dart) | `localizeServiceError` (central mapper, the only localization point) |
| [`lib/components/views/service_error_view.dart`](../../lib/components/views/service_error_view.dart) | `ServiceErrorView` (shared empty-state widget for fetch failures) |
| [`lib/page/dmz/`](../../lib/page/dmz/) | Type A (state.error) full reference: service / notifier / view |
| [`lib/page/admin/`](../../lib/page/admin/) | AsyncValue (AsyncValue.error) reference |
| `lib/l10n/app_en.arb` | error message ARB key (`errorXxx`) |
