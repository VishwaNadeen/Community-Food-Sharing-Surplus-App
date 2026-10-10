import { beforeEach, describe, expect, it, vi } from 'vitest';

const { prismaMock } = vi.hoisted(() => ({
    prismaMock: {
        user: { findMany: vi.fn() },
        recipient: { findMany: vi.fn() },
        foodDonation: { findMany: vi.fn() },
        foodRequest: { findMany: vi.fn() },
        deliveryProblem: {
            findMany: vi.fn(),
            findUnique: vi.fn(),
            update: vi.fn()
        }
    }
}));

vi.mock('@prisma/client', async () => {
    const actual = await vi.importActual<typeof import('@prisma/client')>('@prisma/client');
    return { ...actual, PrismaClient: vi.fn(() => prismaMock) };
});

import {
    AdminValidationError,
    getAlerts,
    getDonorSummaries,
    getRecipientSummaries,
    updateAlertStatus
} from '../src/services/ngoAdmin.service';

const daysAgo = (days: number) => new Date(Date.now() - days * 24 * 60 * 60 * 1000);
const validId = 'a'.repeat(24);

describe('NGO administration data', () => {
    beforeEach(() => vi.clearAllMocks());

    it('summarises donors from their real donations', async () => {
        prismaMock.user.findMany.mockResolvedValue([
            { id: 'd1', customUserId: 'D-1', email: 'a@x.com', createdAt: daysAgo(200) },
            { id: 'd2', customUserId: 'D-2', email: 'b@x.com', createdAt: daysAgo(10) },
            { id: 'd3', customUserId: 'D-3', email: 'c@x.com', createdAt: daysAgo(5) }
        ]);
        prismaMock.foodDonation.findMany.mockResolvedValue([
            { donorId: 'd1', status: 'APPROVED', createdAt: daysAgo(3) },
            { donorId: 'd1', status: 'PENDING', createdAt: daysAgo(1) },
            { donorId: 'd1', status: 'REJECTED', createdAt: daysAgo(2) },
            { donorId: 'd2', status: 'APPROVED', createdAt: daysAgo(150) }
        ]);

        const donors = await getDonorSummaries();

        expect(donors.map((d) => d.customUserId)).toEqual(['D-1', 'D-2', 'D-3']);
        expect(donors[0]).toMatchObject({
            totalDonations: 3,
            approvedDonations: 1,
            pendingDonations: 1,
            rejectedDonations: 1,
            status: 'ACTIVE'
        });
        expect(donors[1].status).toBe('INACTIVE');
        expect(donors[2]).toMatchObject({ totalDonations: 0, status: 'NEW' });
    });

    it('summarises recipients from their real requests', async () => {
        prismaMock.recipient.findMany.mockResolvedValue([{
            customUserId: 'R-1',
            firstName: 'Nimal',
            lastName: 'Perera',
            phoneNumber: '0771234567',
            city: 'Colombo',
            district: 'Colombo',
            createdAt: daysAgo(30),
            user: { email: 'r@x.com' }
        }]);
        prismaMock.foodRequest.findMany.mockResolvedValue([
            { recipientId: 'R-1', status: 'APPROVED', createdAt: daysAgo(2) },
            { recipientId: 'R-1', status: 'PENDING', createdAt: daysAgo(1) },
            { recipientId: 'R-1', status: 'REJECTED', createdAt: daysAgo(4) }
        ]);

        const [recipient] = await getRecipientSummaries();

        expect(recipient).toMatchObject({
            name: 'Nimal Perera',
            location: 'Colombo, Colombo',
            totalRequests: 3,
            approvedRequests: 1,
            pendingRequests: 1,
            rejectedRequests: 1,
            status: 'ACTIVE'
        });
    });

    it('lists open delivery problems before resolved ones', async () => {
        const delivery = {
            foodItem: 'Rice',
            status: 'IN_TRANSIT',
            pickupAddress: 'A',
            dropoffAddress: 'B'
        };
        prismaMock.deliveryProblem.findMany.mockResolvedValue([
            {
                id: 'p1', deliveryId: 'x', volunteerId: 'V-1', problemType: 'Delay',
                description: 'Traffic', status: 'RESOLVED',
                createdAt: daysAgo(1), updatedAt: daysAgo(0), delivery
            },
            {
                id: 'p2', deliveryId: 'y', volunteerId: 'V-2', problemType: 'Damaged',
                description: 'Spilled', status: 'REPORTED',
                createdAt: daysAgo(5), updatedAt: daysAgo(5), delivery
            }
        ]);

        const result = await getAlerts();

        expect(result.alerts.map((a) => a.id)).toEqual(['p2', 'p1']);
        expect(result.counts).toEqual({ reported: 1, acknowledged: 0, resolved: 1 });
    });

    it('validates alert status updates', async () => {
        await expect(updateAlertStatus('bad-id', 'RESOLVED')).rejects.toBeInstanceOf(AdminValidationError);
        await expect(updateAlertStatus(validId, 'REPORTED')).rejects.toThrow('ACKNOWLEDGED or RESOLVED');

        prismaMock.deliveryProblem.findUnique.mockResolvedValueOnce(null);
        await expect(updateAlertStatus(validId, 'RESOLVED')).rejects.toMatchObject({ statusCode: 404 });

        prismaMock.deliveryProblem.findUnique.mockResolvedValueOnce({ id: validId, status: 'RESOLVED' });
        await expect(updateAlertStatus(validId, 'ACKNOWLEDGED')).rejects.toThrow('already resolved');
        expect(prismaMock.deliveryProblem.update).not.toHaveBeenCalled();
    });

    it('updates an open alert', async () => {
        prismaMock.deliveryProblem.findUnique.mockResolvedValue({ id: validId, status: 'REPORTED' });
        prismaMock.deliveryProblem.update.mockResolvedValue({ id: validId, status: 'ACKNOWLEDGED' });

        await updateAlertStatus(validId, 'ACKNOWLEDGED');

        expect(prismaMock.deliveryProblem.update).toHaveBeenCalledWith({
            where: { id: validId },
            data: { status: 'ACKNOWLEDGED' }
        });
    });
});
