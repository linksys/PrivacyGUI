/// AI module for Router AI Assistant.
///
/// This module provides:
/// - [IRouterCommandProvider] - Abstract interface for router command providers
/// - [UspCommandProvider] - USP-based implementation using dashboard providers
/// - [RouterChatController] - Manages conversation state with confirmation flow
/// - [RouterSystemPrompt] - System prompt templates
/// - [RouterComponentRegistry] - Component registry with router-specific widgets
library ai;

export 'abstraction/_abstraction.dart';
export 'providers/_providers.dart';
export 'orchestrator/_orchestrator.dart';
export 'prompts/_prompts.dart';
export 'registry/_registry.dart';
