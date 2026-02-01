/// CONTRACT A: Event Schema (Inbound from Integrations/Rocket.new)
class IntegrationEvent {
  final String eventId;
  final String type; // MOTION, DOORBELL, ALEXA
  final String sourceId;
  final Map<String, dynamic> payload;

  IntegrationEvent({
    required this.eventId, 
    required this.type, 
    required this.sourceId, 
    this.payload = const {},
  });
  
  // factory fromJson...
}

/// CONTRACT B: Action Schema (Outbound from Rules -> App Executor)
/// The Mobile App is the Executor. It receives this and applies it to WLED.
class AutomationAction {
  final String actionId;
  final String commandType; // APPLY_PRESET, SET_BRIGHTNESS, POWER
  final dynamic value;
  
  // Targets
  final List<String> targetZones; // ['Zone 1'] or ['ALL']
  
  // Universal Dimming Policy (Contract)
  final String brightnessPolicy; // 'INHERIT' or 'OVERRIDE'
  final int? brightnessOverride;

  AutomationAction({
    required this.actionId,
    required this.commandType,
    this.value,
    this.targetZones = const ['ALL'],
    this.brightnessPolicy = 'INHERIT',
    this.brightnessOverride,
  });

  // factory fromJson...
}
