import 'package:flutter/material.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/components/faq_component_registry.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/constants.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/generators/bedrock_faq_generator.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/generators/direct_search_generator.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Floating FAQ Agent component
///
/// Floating button in the bottom right corner, click to expand the search dialog.
/// Search for FAQ articles using the Linksys Support API and analyze the results via AWS Bedrock LLM.
class FAQAgentFab extends StatefulWidget {
  const FAQAgentFab({super.key});

  @override
  State<FAQAgentFab> createState() => _FAQAgentFabState();
}

class _FAQAgentFabState extends State<FAQAgentFab> {
  bool _isExpanded = false;
  final _containerKey = GlobalKey<GenUiContainerState>();
  final _inputController = TextEditingController();

  late final OrchestrateUIFlowUseCase _orchestrator;
  late final IComponentRegistry _registry;
  bool _useMock = true;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _setupGenUI();
  }

  void _setupGenUI() {
    _registry = createFaqComponentRegistry(onRetry: _retryLastQuery);

    IContentGenerator generator;
    try {
      final config = AWSConfig.fromEnvironment();
      debugPrint('FAQ Agent: Using AWS Bedrock - $config');
      generator = BedrockFAQGenerator(config: config);
      _useMock = false;
    } on ConfigurationException catch (e) {
      debugPrint('FAQ Agent: AWS config failed: ${e.message}');
      debugPrint('FAQ Agent: Falling back to direct Linksys search');
      generator = DirectSearchGenerator();
      _useMock = true;
    } catch (e) {
      debugPrint('FAQ Agent: Unexpected error: $e');
      generator = DirectSearchGenerator();
      _useMock = true;
    }

    _orchestrator = OrchestrateUIFlowUseCase(contentGenerator: generator);
  }

  void _retryLastQuery() {
    if (_lastQuery.isNotEmpty) {
      _containerKey.currentState?.sendMessage(_lastQuery);
    }
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _ask() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _lastQuery = text;
    _containerKey.currentState?.sendMessage(text);
    _inputController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _isExpanded ? kExpandedWidth : kFabSize,
      height: _isExpanded ? kExpandedHeight : kFabSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          if (_isExpanded)
            Positioned(
              bottom: kFabBottomOffset,
              right: 0,
              child: _buildChatPanel(colorScheme),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildFab(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(ColorScheme colorScheme) {
    return FloatingActionButton(
      heroTag: 'faq-agent-fab',
      onPressed: _toggle,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      child: AnimatedSwitcher(
        duration: kIconSwitchDuration,
        child: AppIcon.font(
          _isExpanded ? Icons.close : Icons.support_agent,
          key: ValueKey(_isExpanded),
        ),
      ),
    );
  }

  Widget _buildChatPanel(ColorScheme colorScheme) {
    return AppSurface(
      variant: SurfaceVariant.elevated,
      width: kPanelWidth,
      height: kPanelHeight,
      borderRadius: kPanelBorderRadius,
      child: Column(
        children: [
          _buildHeader(colorScheme),
          Expanded(
            child: GenUiContainer(
              key: _containerKey,
              orchestrator: _orchestrator,
              registry: _registry,
            ),
          ),
          _buildInputBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(kPanelBorderRadius)),
      ),
      child: Row(
        children: [
          AppIcon.font(Icons.support_agent,
              color: colorScheme.onPrimaryContainer),
          AppGap.sm(),
          AppText.titleMedium(
            'FAQ Assistant',
            color: colorScheme.onPrimaryContainer,
          ),
          const Spacer(),
          AppTag(
            label: _useMock ? 'Search' : 'AI',
            color: _useMock ? Colors.orange : Colors.green,
          ),
          AppGap.sm(),
          AppIconButton.icon(
            icon: AppIcon.font(
              Icons.close,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
            onTap: _toggle,
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _inputController,
              hintText: 'Search for help topics...',
              onSubmitted: (_) => _ask(),
            ),
          ),
          AppGap.sm(),
          AppIconButton(
            icon: const Icon(Icons.search),
            onTap: _ask,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
