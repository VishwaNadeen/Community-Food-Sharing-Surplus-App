import { beforeEach, describe, expect, it, vi } from 'vitest';

const { prismaMock } = vi.hoisted(() => ({
    prismaMock: {
        delivery: { findMany: vi.fn() },
        volunteerAvailability: { findMany: vi.fn() }
    }
}));

vi.mock('@prisma/client', async () => {
    const actual = await vi.importActual<typeof import('@prisma/client')>('@prisma/client');
    return {
        ...actual,
        PrismaClient: vi.fn(() => prismaMock)
    };
});

import { getVolunteerActivityAnalytics } from '../src/services/ngoImpact.service';

describe('NGO volunteer activity analytics', () => {
    beforeEach(() => vi.clearAllMocks());

    it('aggregates volunteer counts and delivery activity from live records', async () => {
        prismaMock.delivery.findMany.mockResolvedValue([
            {
                volunteerId: 'V-1',
                status: 'DELIVERED',
                deliveredAt: new Date('2026-10-02T10:00:00.000Z')
            },
            {
                volunteerId: 'V-1',
                status: 'IN_TRANSIT',
                deliveredAt: null
            },
            {
                volunteerId: 'V-2',
                status: 'PENDING_ASSIGNMENT',
                deliveredAt: null
            }
        ]);
        prismaMock.volunteerAvailability.findMany.mockResolvedValue([
            { volunteerId: 'V-1', status: 'AVAILABLE' },
            { volunteerId: 'V-3', status: 'UNAVAILABLE' }
        ]);

        const result = await getVolunteerActivityAnalytics();

        expect(result).toMatchObject({
            totalVolunteers: 3,
            availableVolunteers: 1,
            totalAssignedDeliveries: 3,
            completedDeliveries: 1,
            activeDeliveries: 1,
            deliveryStatusCounts: {
                DELIVERED: 1,
                IN_TRANSIT: 1,
                PENDING_ASSIGNMENT: 1
            }
        });
        expect(result.volunteers[0]).toMatchObject({
            volunteerId: 'V-1',
            totalDeliveries: 2,
            completedDeliveries: 1,
            activeDeliveries: 1,
            lastDeliveredAt: '2026-10-02T10:00:00.000Z'
        });
    });

    it('returns zeroed statistics when there is no volunteer activity', async () => {
        prismaMock.delivery.findMany.mockResolvedValue([]);
        prismaMock.volunteerAvailability.findMany.mockResolvedValue([]);

        await expect(getVolunteerActivityAnalytics()).resolves.toMatchObject({
            totalVolunteers: 0,
            availableVolunteers: 0,
            totalAssignedDeliveries: 0,
            completedDeliveries: 0,
            activeDeliveries: 0,
            deliveryStatusCounts: {},
            volunteers: []
        });
    });
});
