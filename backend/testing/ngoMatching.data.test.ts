import { beforeEach, describe, expect, it, vi } from 'vitest';

const prismaMocks = vi.hoisted(() => ({
    findMatches: vi.fn(),
    findDonations: vi.fn(),
    findRequests: vi.fn(),
    deleteMatches: vi.fn()
}));

vi.mock('@prisma/client', () => ({
    DonationStatus: {
        APPROVED: 'APPROVED',
        AVAILABLE: 'AVAILABLE'
    },
    PrismaClient: vi.fn().mockImplementation(() => ({
        foodMatch: {
            findMany: prismaMocks.findMatches,
            deleteMany: prismaMocks.deleteMatches
        },
        foodDonation: {
            findMany: prismaMocks.findDonations
        },
        foodRequest: {
            findMany: prismaMocks.findRequests
        }
    }))
}));

import { getFoodMatches } from '../src/services/ngoMatching.service';

describe('stored food matches', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('removes matches whose donation or request no longer exists', async () => {
        prismaMocks.findMatches.mockResolvedValue([
            {
                id: 'match-1',
                donationId: 'donation-deleted',
                foodRequestId: 'request-1',
                score: 100,
                matchedAt: new Date()
            }
        ]);
        prismaMocks.findDonations.mockResolvedValue([]);
        prismaMocks.findRequests.mockResolvedValue([
            { id: 'request-1', customRequestId: 'FR-1' }
        ]);
        prismaMocks.deleteMatches.mockResolvedValue({ count: 1 });

        const result = await getFoodMatches();

        expect(result).toEqual([]);
        expect(prismaMocks.deleteMatches).toHaveBeenCalledWith({
            where: { id: { in: ['match-1'] } }
        });
    });

    it('removes matches for donations or requests that are no longer eligible', async () => {
        prismaMocks.findMatches.mockResolvedValue([
            {
                id: 'match-rejected',
                donationId: 'donation-1',
                foodRequestId: 'request-1',
                score: 100,
                matchedAt: new Date()
            }
        ]);
        prismaMocks.findDonations.mockResolvedValue([
            {
                id: 'donation-1',
                status: 'REJECTED',
                expiryDate: new Date(Date.now() + 60_000),
                pickupDateTime: new Date(Date.now() + 60_000)
            }
        ]);
        prismaMocks.findRequests.mockResolvedValue([
            { id: 'request-1', status: 'APPROVED' }
        ]);
        prismaMocks.deleteMatches.mockResolvedValue({ count: 1 });

        const result = await getFoodMatches();

        expect(result).toEqual([]);
        expect(prismaMocks.deleteMatches).toHaveBeenCalledWith({
            where: { id: { in: ['match-rejected'] } }
        });
    });

    it('does not return matches for expired donations', async () => {
        prismaMocks.findMatches.mockResolvedValue([
            {
                id: 'match-expired',
                donationId: 'donation-1',
                foodRequestId: 'request-1',
                score: 100,
                matchedAt: new Date()
            }
        ]);
        prismaMocks.findDonations.mockResolvedValue([
            {
                id: 'donation-1',
                status: 'APPROVED',
                expiryDate: new Date(Date.now() - 60_000),
                pickupDateTime: new Date(Date.now() + 60_000)
            }
        ]);
        prismaMocks.findRequests.mockResolvedValue([
            { id: 'request-1', status: 'APPROVED' }
        ]);
        prismaMocks.deleteMatches.mockResolvedValue({ count: 1 });

        const result = await getFoodMatches();

        expect(result).toEqual([]);
        expect(prismaMocks.deleteMatches).toHaveBeenCalledWith({
            where: { id: { in: ['match-expired'] } }
        });
    });

    it('removes matches when the food request is no longer approved', async () => {
        prismaMocks.findMatches.mockResolvedValue([
            {
                id: 'match-unapproved-request',
                donationId: 'donation-1',
                foodRequestId: 'request-1',
                score: 100,
                matchedAt: new Date()
            }
        ]);
        prismaMocks.findDonations.mockResolvedValue([
            {
                id: 'donation-1',
                status: 'APPROVED',
                expiryDate: new Date(Date.now() + 60_000),
                pickupDateTime: new Date(Date.now() + 60_000)
            }
        ]);
        prismaMocks.findRequests.mockResolvedValue([
            { id: 'request-1', status: 'REJECTED' }
        ]);
        prismaMocks.deleteMatches.mockResolvedValue({ count: 1 });

        const result = await getFoodMatches();

        expect(result).toEqual([]);
        expect(prismaMocks.deleteMatches).toHaveBeenCalledWith({
            where: { id: { in: ['match-unapproved-request'] } }
        });
    });
});
