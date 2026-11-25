import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/soft_sku_settings.dart';

void main() {
  test('reads the model number the router sells as', () {
    final settings = SoftSKUSettings.fromJson('{"modelNumber": "LN16-EU"}');

    expect(settings.modelNumber, 'LN16-EU');
    expect(settings.toMap(), {'modelNumber': 'LN16-EU'});
  });

  test('survives a trip through JSON text, and copies', () {
    const settings = SoftSKUSettings(modelNumber: 'LN16-EU');

    expect(SoftSKUSettings.fromJson(settings.toJson()), settings);
    expect(settings.copyWith(modelNumber: 'M63TS-EU').modelNumber, 'M63TS-EU');
    expect(settings.copyWith(), settings);
  });
}
