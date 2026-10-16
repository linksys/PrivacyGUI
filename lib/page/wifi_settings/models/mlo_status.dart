/// `Device.X_LINKSYS_Mesh.MLOStatus` (linksys/FWDEV#201): whether MLO runs.
enum MloStatus {
  /// The switch is off.
  disabled,

  /// The 2.4 and 5 GHz main networks run as one AP MLD.
  active,

  /// The switch is on, but the bands' SSID, password or security do not allow
  /// MLO. WPA2 and Open never do.
  inactive,

  /// A value outside the contract's three.
  unknown;

  static MloStatus fromTr181(String value) => switch (value) {
        'Disabled' => disabled,
        'Active' => active,
        'Inactive' => inactive,
        _ => unknown,
      };
}
