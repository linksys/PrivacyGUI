/// The unit a temperature is shown in (#1926).
enum TemperatureUnit { celsius, fahrenheit }

/// The unit people in [countryCode] expect when nothing has been picked.
///
/// From CLDR's `unitPreferenceData`, category `temperature`, usage `default`:
/// Fahrenheit for `US`, Celsius everywhere else. The `weather` usage adds BS, BZ,
/// KY, PR and PW, but a router's temperature is not weather. A locale with no
/// region reads Celsius.
TemperatureUnit temperatureUnitForRegion(String? countryCode) =>
    countryCode == 'US' ? TemperatureUnit.fahrenheit : TemperatureUnit.celsius;

/// [celsius] in whole °F, rounded.
int fahrenheitOf(int celsius) => (celsius * 9 / 5 + 32).round();
