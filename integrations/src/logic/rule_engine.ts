import { IntegrationEvent, AutomationAction } from '../domain/schemas';
import { v4 as uuidv4 } from 'uuid'; // Assumption: user will install uuid or we mock it. 
// For this environment, we'll use a simple random string generator to avoid npm install dependency issues in this simulated environment.
const generateId = () => Math.random().toString(36).substring(7);

/**
 * Core Logic Engine
 * "Rocket.new" Logic Layer
 */
export class RuleEngine {

    public processEvent(event: IntegrationEvent): AutomationAction | null {
        console.log(`[RuleEngine] Processing ${event.type} from ${event.sourceId}`);

        switch (event.type) {
            case 'MOTION':
                return this.handleMotion(event);
            case 'DOORBELL':
                return this.handleDoorbell(event);
            case 'ALEXA':
                return this.handleAlexa(event);
            default:
                console.warn(`[RuleEngine] No rule for type ${event.type}`);
                return null;
        }
    }

    /**
     * Rule: Motion detected -> Set Zone 1 (Entryway) to 80% Brightness (Warm Welcome).
     * Note: Does NOT use Global Presets to avoid affecting other zones.
     */
    private handleMotion(event: IntegrationEvent): AutomationAction {
        return {
            actionId: generateId(),
            commandType: 'SET_BRIGHTNESS',
            value: 200, // ~80%
            targetZones: ['ZONE_1'],
            brightnessPolicy: 'INHERIT', // Let global dimmer scale it if needed, but usually we want visibility.
            // Correction: If we want "Warm Welcome", we might need to set Effect too, 
            // but 'SET_BRIGHTNESS' is the primary safety action.
        };
    }

    /**
     * Rule: Doorbell pressed -> Flash/Notify Zone 1 & 2.
     * Action: Set high brightness override.
     */
    private handleDoorbell(event: IntegrationEvent): AutomationAction {
        return {
            actionId: generateId(),
            commandType: 'SET_BRIGHTNESS',
            value: 255,
            targetZones: ['ZONE_1', 'ZONE_2'],
            brightnessPolicy: 'OVERRIDE',
            brightnessOverride: 255, // Force visibility
        };
    }

    /**
     * Rule: Alexa "Turn On" -> Power On Everything
     */
    private handleAlexa(event: IntegrationEvent): AutomationAction {
        // Check payload for specific intent? 
        // For V1, assume "Turn On" generic.
        return {
            actionId: generateId(),
            commandType: 'POWER',
            value: true,
            targetZones: ['ALL'],
            brightnessPolicy: 'INHERIT',
        };
    }
}
