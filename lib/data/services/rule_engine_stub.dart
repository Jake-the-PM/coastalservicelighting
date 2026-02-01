import '../../domain/contracts/schemas.dart';
import '../services/automation_service.dart';

/// SIMULATOR: Acts as the "Cloud" or "Rocket.new" engine locally.
/// Maps INBOUND Events -> OUTBOUND Actions.
class RuleEngineStub {
  final AutomationService _automationService;

  RuleEngineStub(this._automationService);

  Future<void> ingestEvent(IntegrationEvent event) async {
    print("STUB: Ingesting Event ${event.type}");
    
    // Simulate Processing Latency
    await Future.delayed(const Duration(milliseconds: 50));

    // Rule Logic (Mocking Rocket.new)
    AutomationAction? action;

    switch (event.type) {
      case 'MOTION':
        // Rule: If Motion detected -> Set Zone 1 to 80% Brightness (Warm Welcome)
        // Correcting Trace 3: Did not use APPLY_PRESET because that is Global. Used Per-Zone brightness.
        action = AutomationAction(
          actionId: 'mock-action-001',
          commandType: 'SET_BRIGHTNESS', // changed from APPLY_PRESET
          value: 200, // ~80%
          targetZones: ['ZONE_1'],
          brightnessPolicy: 'INHERIT', 
        );
        break;

      case 'DOORBELL':
        // Rule: If Doorbell -> Flash Zone 1 & 2
        // Note: Complex sequences might be handled by a special Preset or sequence of Actions.
        // For V1, let's just turn them ON to Bright.
        action = AutomationAction(
          actionId: 'mock-action-002',
          commandType: 'SET_BRIGHTNESS',
          value: 255,
          targetZones: ['ZONE_1', 'ZONE_2'],
          brightnessPolicy: 'OVERRIDE',
          brightnessOverride: 255,
        );
        break;

      case 'ALEXA':
        // Rule: Alexa says "Turn on Lights" -> Power On All
        action = AutomationAction(
          actionId: 'mock-action-003',
          commandType: 'POWER',
          value: true,
          targetZones: ['ALL'],
        );
        break;
    }

    if (action != null) {
      print("STUB: Dispatching Action ${action.commandType}");
      await _automationService.executeAction(action);
    }
  }
}
