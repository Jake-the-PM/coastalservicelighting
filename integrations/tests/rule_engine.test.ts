import { RuleEngine } from '../src/logic/rule_engine';
import { IntegrationEvent } from '../src/domain/schemas';

describe('Rule Engine Logic', () => {
    let engine: RuleEngine;

    beforeEach(() => {
        engine = new RuleEngine();
    });

    test('Motion Event should trigger Zone 1 Brightness', () => {
        const event: IntegrationEvent = {
            eventId: '123',
            type: 'MOTION',
            sourceId: 'sensor-1',
            timestamp: new Date().toISOString()
        };

        const action = engine.processEvent(event);

        expect(action).not.toBeNull();
        expect(action?.commandType).toBe('SET_BRIGHTNESS');
        expect(action?.targetZones).toContain('ZONE_1');
        expect(action?.targetZones).not.toContain('ZONE_2');
        expect(action?.value).toBe(200);
    });

    test('Doorbell Event should trigger Zone 1 & 2 Override', () => {
        const event: IntegrationEvent = {
            eventId: '456',
            type: 'DOORBELL',
            sourceId: 'doorbell-1',
            timestamp: new Date().toISOString()
        };

        const action = engine.processEvent(event);

        expect(action).not.toBeNull();
        expect(action?.commandType).toBe('SET_BRIGHTNESS');
        expect(action?.targetZones).toContain('ZONE_1');
        expect(action?.targetZones).toContain('ZONE_2');
        expect(action?.brightnessPolicy).toBe('OVERRIDE');
        expect(action?.brightnessOverride).toBe(255);
    });

    test('Alexa Event should trigger Power All', () => {
        const event: IntegrationEvent = {
            eventId: '789',
            type: 'ALEXA',
            sourceId: 'alexa-skill',
            timestamp: new Date().toISOString()
        };

        const action = engine.processEvent(event);

        expect(action).not.toBeNull();
        expect(action?.commandType).toBe('POWER');
        expect(action?.targetZones).toContain('ALL');
        expect(action?.value).toBe(true);
    });
});
