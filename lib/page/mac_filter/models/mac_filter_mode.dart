/// The network-wide MAC filter mode (`X_LINKSYS_MACFilterMode`).
///
/// Instant Privacy is this feature in [allow] mode; the MAC Filter page also
/// offers [deny]. The wire values are the exact strings the firmware accepts.
enum MacFilterMode {
  disabled('Disabled'),
  allow('Allow'),
  deny('Deny');

  const MacFilterMode(this.wire);
  final String wire;

  static MacFilterMode fromWire(String value) => switch (value) {
        'Allow' => MacFilterMode.allow,
        'Deny' => MacFilterMode.deny,
        // Anything else (including 'Disabled' and any unexpected value) is
        // treated as off — the safe default for a filter.
        _ => MacFilterMode.disabled,
      };
}
