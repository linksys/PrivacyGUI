/// AI module for Router AI Assistant.
///
/// This module provides:
/// - [IRouterCommandProvider] - Abstract interface for router command providers
/// - [UspCommandProvider] - USP-based implementation using dashboard providers
/// - [RouterChatController] - Manages conversation state with confirmation flow
/// - [RouterSystemPrompt] - System prompt templates
/// - [RouterComponentRegistry] - Component registry with router-specific widgets
///
/// ## Localization policy (#1253)
///
/// Every user-visible literal in `components/` and `registry/` resolves through
/// `loc(context)` — 141 call sites over 93 keys. Do not add a bare string
/// literal to a widget here; #1253 was filed because this subsystem had 130 of
/// them and touched `AppLocalizations` nowhere.
///
/// **41 of those 93 keys exist in `app_en.arb` only, and that is deliberate.**
/// They are not machine-translated: Flutter's ARB fallback serves the template
/// value, so a non-English locale renders them in English by design. This
/// follows the existing precedent of `edit`, `optimizeLayout` and `refresh`,
/// which ship English-only for the same reason. The other 52 keys reuse
/// pre-existing entries already translated into all 26 locales.
///
/// Recorded here rather than in the commit message alone so the gap is not
/// re-raised per file, and so nobody "completes" it one string at a time — the
/// failure mode #1253 explicitly ruled out. Translating the 41 is a product
/// decision, not a cleanup; #1253 is still open and is where to make it.
library ai;

export 'abstraction/_abstraction.dart';
export 'providers/_providers.dart';
export 'orchestrator/_orchestrator.dart';
export 'prompts/_prompts.dart';
export 'registry/_registry.dart';
