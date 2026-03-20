import 'package:privacy_gui/generated/subscriptions.g.dart' as generated;

/// Re-exports the auto-generated core SSE subscription list so that
/// non-service layers (e.g. orchestrators) don't import codegen directly.
const coreSubscriptions = generated.coreSubscriptions;
