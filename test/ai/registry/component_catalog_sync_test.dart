import 'package:flutter_test/flutter_test.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:privacy_gui/ai/registry/component_catalog.dart';
import 'package:privacy_gui/ai/registry/router_component_registry.dart';
import 'package:privacy_gui/ai/prompts/router_system_prompt.dart';

void main() {
  group('ComponentCatalog sync validation', () {
    late ComponentRegistry registry;

    setUp(() {
      registry = RouterComponentRegistry.create();
    });

    test('all catalog components are registered in RouterComponentRegistry',
        () {
      final catalogNames = ComponentCatalog.allComponentNames;
      final registeredNames = registry.registeredComponents;

      final missingFromRegistry = <String>[];
      for (final name in catalogNames) {
        if (!registeredNames.contains(name)) {
          missingFromRegistry.add(name);
        }
      }

      expect(
        missingFromRegistry,
        isEmpty,
        reason:
            'Components in catalog but not registered: $missingFromRegistry\n'
            'Add these to RouterComponentRegistry._registerRouterComponents()',
      );
    });

    test('catalog is a subset of registered components', () {
      final catalogNames = ComponentCatalog.allComponentNames;
      final registeredNames = registry.registeredComponents.toSet();

      // Catalog should only contain components that are actually registered
      // (it doesn't need to contain ALL registered components, just the ones
      // we want to expose to the AI)
      final catalogNotRegistered = <String>[];
      for (final name in catalogNames) {
        if (!registeredNames.contains(name)) {
          catalogNotRegistered.add(name);
        }
      }

      expect(
        catalogNotRegistered,
        isEmpty,
        reason:
            'Components in catalog but not registered: $catalogNotRegistered\n'
            'Remove from ComponentCatalog or add to RouterComponentRegistry',
      );
    });

    test('all data sections are mentioned in system prompt', () {
      final prompt = RouterSystemPrompt.build();
      final dataSections = ComponentCatalog.dataSectionNames;

      final missingFromPrompt = <String>[];
      for (final name in dataSections) {
        if (!prompt.contains(name)) {
          missingFromPrompt.add(name);
        }
      }

      expect(
        missingFromPrompt,
        isEmpty,
        reason:
            'Data sections not mentioned in system prompt: $missingFromPrompt\n'
            'Add these to RouterSystemPrompt._componentGuide',
      );
    });

    test('all legacy cards are mentioned in system prompt', () {
      final prompt = RouterSystemPrompt.build();
      final legacyCards = ComponentCatalog.legacyCardNames;

      final missingFromPrompt = <String>[];
      for (final name in legacyCards) {
        if (!prompt.contains(name)) {
          missingFromPrompt.add(name);
        }
      }

      expect(
        missingFromPrompt,
        isEmpty,
        reason:
            'Legacy cards not mentioned in system prompt: $missingFromPrompt\n'
            'Add these to RouterSystemPrompt._componentGuide',
      );
    });

    test('catalog has correct component count', () {
      expect(
        ComponentCatalog.components.length,
        37,
        reason: 'Expected 37 components:\n'
            '- 16 data sections (9 domain + 2 utilities + 2 advanced + 3 charts)\n'
            '- 9 legacy cards\n'
            '- 3 basic display\n'
            '- 3 containers\n'
            '- 4 layout\n'
            '- 2 interactive',
      );
    });

    test('catalog categories have expected counts', () {
      expect(
        ComponentCatalog.byCategory(ComponentCategory.dataSection).length,
        16,
        reason:
            'Expected 16 data sections (9 domain + 2 utilities + 2 advanced + 3 charts)',
      );
      expect(
        ComponentCatalog.byCategory(ComponentCategory.legacyCard).length,
        9,
        reason: 'Expected 9 legacy cards',
      );
      expect(
        ComponentCatalog.byCategory(ComponentCategory.basicDisplay).length,
        3,
        reason: 'Expected 3 basic display components',
      );
      expect(
        ComponentCatalog.byCategory(ComponentCategory.container).length,
        3,
        reason: 'Expected 3 container components',
      );
      expect(
        ComponentCatalog.byCategory(ComponentCategory.layout).length,
        4,
        reason: 'Expected 4 layout components',
      );
      expect(
        ComponentCatalog.byCategory(ComponentCategory.interactive).length,
        2,
        reason: 'Expected 2 interactive components',
      );
    });

    test('findByName returns correct component', () {
      final card = ComponentCatalog.findByName('NetworkStatusCard');
      expect(card, isNotNull);
      expect(card!.category, ComponentCategory.legacyCard);
      expect(card.description, contains('WAN'));

      final section = ComponentCatalog.findByName('WanSection');
      expect(section, isNotNull);
      expect(section!.category, ComponentCategory.dataSection);

      final unknown = ComponentCatalog.findByName('UnknownComponent');
      expect(unknown, isNull);
    });

    test('data sections list is accurate', () {
      final dataSections = ComponentCatalog.dataSectionNames;

      expect(
        dataSections,
        containsAll([
          // Utilities
          'SectionHeader',
          'AiInfoRow',
          // Domain sections
          'WanSection',
          'LanSection',
          'WifiSection',
          'DevicesSection',
          'SystemSection',
          'FirewallSection',
          'EthernetSection',
          'DhcpSection',
          'PortForwardingSection',
          // Advanced sections
          'TopologySection',
          'DiagnosticsSection',
          // Chart sections
          'LineChartSection',
          'BarChartSection',
          'PieChartSection',
        ]),
      );
    });

    test('legacy cards list is accurate', () {
      final legacyCards = ComponentCatalog.legacyCardNames;

      expect(
        legacyCards,
        containsAll([
          'NetworkStatusCard',
          'EthernetPortsCard',
          'LanInfoCard',
          'DhcpCard',
          'FirewallCard',
          'PortForwardingCard',
          'DeviceListView',
          'WifiSettingsCard',
          'SystemResourceCard',
        ]),
      );
    });
  });
}
