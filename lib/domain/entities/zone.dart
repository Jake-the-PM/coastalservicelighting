class Zone {
  final int id; // Physical Port ID (1, 2, 3) --> WLED Segment ID + 1
  final String label; // User-defined name (e.g., "Front")
  final bool isOn;
  final int brightness; // 0-255
  final String controllerIp; // [NEW] The IP of the WLED controller owning this zone

  const Zone({
    required this.id,
    required this.label,
    required this.isOn,
    required this.brightness,
    required this.controllerIp,
  });

  /// Factory for initial default state
  factory Zone.defaultFor(int id, String controllerIp) {
    return Zone(
      id: id,
      label: 'Zone $id',
      isOn: false,
      brightness: 128, // Default 50%
      controllerIp: controllerIp,
    );
  }

  Zone copyWith({
    String? label,
    bool? isOn,
    int? brightness,
    String? controllerIp,
  }) {
    return Zone(
      id: id,
      label: label ?? this.label,
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      controllerIp: controllerIp ?? this.controllerIp,
    );
  }
}
