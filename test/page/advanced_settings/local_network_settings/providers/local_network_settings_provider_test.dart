import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('updateHostName with valid hostname', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('ValidHostname');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'ValidHostname');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name], isNull);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName with empty hostname', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, '');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostName.name);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName with too long hostname', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('HostnameTooLong1'); // 16 chars

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'HostnameTooLong1');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameLengthError.name);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName starting with hyphen', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('-InvalidStart');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, '-InvalidStart');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameStartWithHyphen.name);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName ending with hyphen', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('InvalidEnd-');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'InvalidEnd-');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameEndWithHyphen.name);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName with invalid characters', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('InvalidChar!');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'InvalidChar!');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameInvalidCharacters.name);
    expect(state.hostNameInvalidChars, '!');
  });

  test('updateHostName with multiple invalid characters', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('Invalid@#%');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'Invalid@#%');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameInvalidCharacters.name);
    // Order is now sorted deterministically
    expect(state.hostNameInvalidChars, '#, %, @');
  });

  test('updateHostName with invalid characters clears previous errors', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);

    // First set an error
    notifier.updateHostName('InvalidEnd-');
    expect(
        container
            .read(localNetworkSettingProvider)
            .errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameEndWithHyphen.name);

    // Then set invalid chars
    notifier.updateHostName('InvalidChar!');
    final state = container.read(localNetworkSettingProvider);
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameInvalidCharacters.name);
    expect(state.hostNameInvalidChars, '!');
  });

  test('updateHostName valid input clears errors', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);

    // First set an error
    notifier.updateHostName('InvalidChar!');

    // Then valid input
    notifier.updateHostName('ValidHostname');

    final state = container.read(localNetworkSettingProvider);
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name], isNull);
    expect(state.hostNameInvalidChars,
        isNull); // Should be cleared, although implementing code sets it to null if no invalid chars found?
    // Wait, let's check implementation.
    // In implementation: `invalidChars` is initialized to null. If no invalid chars found, `invalidChars` remains null.
    // `state = state.copyWith(..., hostNameInvalidChars: invalidChars)`
    // So yes, it will be null.
  });
}
