import {describe, expect, it} from 'vitest';
import {
    validateAvailability,
    validateDeliveryProblem,
    validateDeliveryStatus,
    validateGetDeliveriesQuery,
    validateLocation,
    validateRejectDelivery
} from '../src/validators/volunteerDelivery.validator';

describe('volunteer delivery validators', () => {
    it('validates availability and status values', () => {
        expect(validateAvailability({status: 'available'})).toEqual([]);
        expect(validateAvailability({status: 'busy'})).toContain(
            'Status must be AVAILABLE or UNAVAILABLE.'
        );
        expect(validateDeliveryStatus({status: 'delivered'})).toEqual([]);
        expect(validateDeliveryStatus({status: 'accepted'}).length).toBeGreaterThan(0);
    });

    it('validates rejection, location, and problem payloads', () => {
        expect(validateRejectDelivery({rejectionReason: 'No vehicle'})).toEqual([]);
        expect(validateRejectDelivery({rejectionReason: '  '})).toHaveLength(1);
        expect(validateLocation({latitude: 6.9, longitude: 79.8})).toEqual([]);
        expect(validateLocation({latitude: 91, longitude: 79.8})).toHaveLength(1);
        expect(validateDeliveryProblem({problemType: 'vehicle', description: 'Flat tyre'})).toEqual([]);
        expect(validateDeliveryProblem({problemType: 'vehicle'})).toHaveLength(1);
    });

    it('validates delivery filters and expiry sorting', () => {
        expect(validateGetDeliveriesQuery({status: 'PENDING_ASSIGNMENT', sortBy: 'expiry'})).toEqual([]);
        expect(validateGetDeliveriesQuery({status: 'UNKNOWN'})).toHaveLength(1);
        expect(validateGetDeliveriesQuery({sortBy: 'distance'})).toHaveLength(1);
    });
});
