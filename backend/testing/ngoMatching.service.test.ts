import { describe, expect, it, vi } from 'vitest';

vi.mock('@prisma/client', () => ({
    DonationStatus: { APPROVED: 'APPROVED', AVAILABLE: 'AVAILABLE' },
    PrismaClient: vi.fn().mockImplementation(() => ({}))
}));

import {
    isCategoryMatch,
    isDonationAvailable,
    isLocationMatch
} from '../src/services/ngoMatching.service';

describe('food matching criteria', () => {
    it('matches compatible food categories without case sensitivity', () => {
        expect(isCategoryMatch('Rice', 'rice and curry')).toBe(true);
        expect(isCategoryMatch('Dairy', 'Rice and curry')).toBe(false);
    });

    it('matches a pickup location to a recipient city or district', () => {
        expect(isLocationMatch('Malabe, Colombo', {
            customUserId: 'R1',
            city: 'Malabe',
            district: 'Colombo'
        })).toBe(true);
        expect(isLocationMatch('Galle Fort', {
            customUserId: 'R1',
            city: 'Malabe',
            district: 'Colombo'
        })).toBe(false);
    });

    it('rejects expired or past-pickup donations', () => {
        const now = new Date('2026-09-23T10:00:00.000Z');
        expect(isDonationAvailable({
            expiryDate: new Date('2026-09-24T10:00:00.000Z'),
            pickupDateTime: new Date('2026-09-23T11:00:00.000Z')
        }, now)).toBe(true);
        expect(isDonationAvailable({
            expiryDate: new Date('2026-09-22T10:00:00.000Z'),
            pickupDateTime: new Date('2026-09-23T11:00:00.000Z')
        }, now)).toBe(false);
    });
});
