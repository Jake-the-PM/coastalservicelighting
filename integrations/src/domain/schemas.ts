/**
 * Contract A: Inbound Events from External World
 * Matches Dart: IntegrationEvent
 */
export type EventType = 'MOTION' | 'DOORBELL' | 'ALEXA' | 'GENERIC';

export interface IntegrationEvent {
    eventId: string;
    type: EventType;
    sourceId: string;
    payload?: Record<string, any>;
    timestamp: string;
}

/**
 * Contract B: Outbound Actions to Executor (Mobile App)
 * Matches Dart: AutomationAction
 */
export type CommandType = 'POWER' | 'SET_BRIGHTNESS' | 'APPLY_PRESET' | 'SET_EFFECT';
export type BrightnessPolicy = 'INHERIT' | 'OVERRIDE';

export interface AutomationAction {
    actionId: string;
    commandType: CommandType;
    value: any; // bool | int
    targetZones: string[]; // ['ZONE_1'] or ['ALL']

    // Policies (Invariant Enforcement)
    brightnessPolicy: BrightnessPolicy;
    brightnessOverride?: number;
}
