/// The Binding Contract for the Coastal Services App
/// Any deviation from these constants constitutes a breach of the "Build Spec Pack".

class AppSpecs {
  static const String appName = 'Coastal Services';
  
  /// HARDWARE CONTRACT: 3 Independent Physical Ports
  static const int zoneCount = 3;
  static const List<String> defaultZoneLabels = ['Zone 1', 'Zone 2', 'Zone 3'];
  
  /// INVARIANTS (Non-Negotiable)
  /// 1. Offline-First: Core lighting must work via LAN HTTP without internet.
  static const bool offlineFirst = true;

  /// 2. Universal Dimming: Global dimmer serves as Post-Output Scaling (Method B).
  /// No automation or preset can disable this.
  static const bool universalDimming = true;
  
  /// 3. Integration Boundary: Integrations emit events; App executes actions.
  static const bool appIsExecutor = true;

  // Timeouts & UX
  static const Duration lanDiscoveryTimeout = Duration(seconds: 5);
  static const Duration connectionTimeout = Duration(seconds: 2);
  static const Duration flashDuration = Duration(milliseconds: 1000); // For identifying zones
}
