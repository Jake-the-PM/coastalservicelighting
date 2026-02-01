import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Semantic labels and accessibility constants for the app
class A11yLabels {
  // Navigation
  static const String settingsButton = 'Settings';
  static const String backButton = 'Go back';
  static const String closeButton = 'Close';
  static const String menuButton = 'Open menu';
  
  // Installation Management
  static const String addInstallation = 'Add new installation';
  static const String deleteInstallation = 'Delete installation';
  static const String editInstallation = 'Edit installation';
  static const String installationCard = 'Installation card';
  
  // Lighting Control
  static const String brightnessSlider = 'Brightness control';
  static const String powerToggle = 'Power toggle';
  static const String colorPicker = 'Color picker';
  static const String effectSelector = 'Effect selector';
  static const String presetButton = 'Apply preset';
  
  // Schedule
  static const String addSchedule = 'Add new schedule';
  static const String toggleSchedule = 'Toggle schedule on or off';
  static const String scheduleTriggerType = 'Schedule trigger type';
  static const String scheduleActionType = 'Schedule action type';
  
  // Golden Key
  static const String qrCodeDisplay = 'QR code for installation transfer';
  static const String scanQrCode = 'Scan QR code';
  static const String pasteJsonButton = 'Paste installation JSON';
  
  // Device Discovery
  static const String scanForDevices = 'Scan for WLED devices';
  static const String deviceListItem = 'Discovered device';
  static const String addDevice = 'Add device';
  static const String removeDevice = 'Remove device';
  
  // Network Status
  static const String offlineBanner = 'You are offline. Some features may not be available.';
  static const String onlineStatus = 'Connected to internet';
  static const String offlineStatus = 'No internet connection';
  
  // Loading States
  static const String loading = 'Loading';
  static const String loadingInstallations = 'Loading installations';
  static const String loadingSchedules = 'Loading schedules';
  
  // Empty States
  static const String noInstallations = 'No installations. Add your first installation to get started.';
  static const String noSchedules = 'No schedules. Create a schedule to automate your lights.';
  static const String noDevicesFound = 'No devices found. Make sure WLED devices are on your network.';
}

/// Accessibility wrapper widget for consistent semantics
class A11yWrapper extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool isButton;
  final bool isHeader;
  final VoidCallback? onTap;

  const A11yWrapper({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.isButton = false,
    this.isHeader = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      header: isHeader,
      onTap: onTap,
      child: child,
    );
  }
}

/// Extension methods for adding accessibility to existing widgets
extension A11yExtensions on Widget {
  /// Wrap widget with semantic label
  Widget withSemantics({
    required String label,
    String? hint,
    bool button = false,
    bool header = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      child: this,
    );
  }

  /// Add accessibility for a slider
  Widget withSliderSemantics({
    required String label,
    required double value,
    required double min,
    required double max,
  }) {
    final percentage = ((value - min) / (max - min) * 100).round();
    return Semantics(
      label: '$label, $percentage percent',
      slider: true,
      value: '$percentage%',
      child: this,
    );
  }

  /// Add accessibility for a toggle
  Widget withToggleSemantics({
    required String label,
    required bool isOn,
  }) {
    return Semantics(
      label: label,
      toggled: isOn,
      child: this,
    );
  }
}

/// Focus traversal helper for keyboard navigation
class A11yFocusOrder extends StatelessWidget {
  final int order;
  final Widget child;

  const A11yFocusOrder({
    super.key,
    required this.order,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order.toDouble()),
      child: child,
    );
  }
}

/// Announce important changes to screen readers
class A11yAnnouncer {
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  static void announceError(BuildContext context, String error) {
    SemanticsService.announce('Error: $error', TextDirection.ltr);
  }

  static void announceSuccess(BuildContext context, String message) {
    SemanticsService.announce('Success: $message', TextDirection.ltr);
  }
}

/// Color contrast checker for accessibility compliance
class A11yColorContrast {
  /// Calculate contrast ratio between two colors
  /// WCAG 2.0 requires 4.5:1 for normal text, 3:1 for large text
  static double getContrastRatio(Color foreground, Color background) {
    final l1 = _getLuminance(foreground);
    final l2 = _getLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _getLuminance(Color color) {
    final r = color.red / 255;
    final g = color.green / 255;
    final b = color.blue / 255;

    final rLinear = r <= 0.03928 ? r / 12.92 : ((r + 0.055) / 1.055).pow(2.4);
    final gLinear = g <= 0.03928 ? g / 12.92 : ((g + 0.055) / 1.055).pow(2.4);
    final bLinear = b <= 0.03928 ? b / 12.92 : ((b + 0.055) / 1.055).pow(2.4);

    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }

  static bool meetsWCAGAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  static bool meetsWCAGAAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 7.0;
  }
}

extension _PowExtension on double {
  double pow(double exponent) => this == 0 ? 0 : (this > 0 ? this : -this).pow(exponent) * (this >= 0 ? 1 : -1);
}
