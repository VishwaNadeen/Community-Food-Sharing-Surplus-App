import {beforeEach, describe, expect, it, vi} from 'vitest';

const {prismaMock} = vi.hoisted(() => ({
    prismaMock: {
        delivery: {
            findUnique: vi.fn(),
            findMany: vi.fn(),
            update: vi.fn()
        },
        user: {findUnique: vi.fn()},
        recipient: {findUnique: vi.fn()},
        deliveryTracking: {create: vi.fn(), findMany: vi.fn()},
        deliveryProblem: {create: vi.fn(), findMany: vi.fn()},
        volunteerAvailability: {upsert: vi.fn()}
    }
}));

vi.mock('@prisma/client', async () => {
    const actual = await vi.importActual<typeof import('@prisma/client')>('@prisma/client');
    return {
        ...actual,
        PrismaClient: vi.fn(() => prismaMock)
    };
});

import {
    acceptDelivery,
    getDeliveryById,
    getOptimizedDeliveryRoute,
    getVolunteerDashboardStats,
    haversineDistanceKm,
    rejectDelivery,
    updateDeliveryStatus,
    updateVolunteerLocation,
    reportDeliveryProblem
} from '../src/services/volunteerDelivery.service';

const baseDelivery = (overrides: Record<string, unknown> = {}) => ({
    id: 'delivery-1',
    volunteerId: null,
    donorId: 'donor-1',
    recipientId: 'recipient-1',
    foodItem: 'Rice',
    foodQuantityKg: 5,
    foodExpiryDate: new Date('2026-09-05T12:00:00Z'),
    pickupLatitude: 6.9,
    pickupLongitude: 79.8,
    pickupAddress: 'Donor address',
    dropoffLatitude: 6.92,
    dropoffLongitude: 79.82,
    dropoffAddress: 'Recipient address',
    status: 'PENDING_ASSIGNMENT',
    ...overrides
});

describe('volunteer delivery service', () => {
    beforeEach(() => vi.clearAllMocks());

    it('calculates haversine distance in kilometres', () => {
        expect(haversineDistanceKm(0, 0, 0, 1)).toBeCloseTo(111.19, 1);
    });

    it('enriches available deliveries and permits pre-acceptance access', async () => {
        prismaMock.delivery.findUnique.mockResolvedValue(baseDelivery());
        prismaMock.user.findUnique.mockResolvedValue({email: 'donor@example.com'});
        prismaMock.recipient.findUnique.mockResolvedValue({
            firstName: 'Ada', lastName: 'Lovelace', phoneNumber: '555-0100',
            addressLine1: '1 Main St', addressLine2: null, city: 'Colombo', district: 'West'
        });

        const result = await getDeliveryById('delivery-1', 'volunteer-1');

        expect(result.donor).toEqual({email: 'donor@example.com'});
        expect(result.recipient).toMatchObject({name: 'Ada Lovelace', phoneNumber: '555-0100'});
        expect(result.distanceKm).toBeGreaterThan(0);
        expect(result.expiryUrgencyHours).toBeTypeOf('number');
    });

    it('assigns the accepting volunteer and records acceptance', async () => {
        prismaMock.delivery.findUnique.mockResolvedValue(baseDelivery());
        const updated = baseDelivery({volunteerId: 'volunteer-1', status: 'ACCEPTED'});
        prismaMock.delivery.update.mockResolvedValue(updated);
        prismaMock.deliveryTracking.create.mockResolvedValue({id: 'tracking-1'});

        const result = await acceptDelivery('delivery-1', 'volunteer-1');

        expect(prismaMock.delivery.update).toHaveBeenCalledWith(expect.objectContaining({
            data: expect.objectContaining({volunteerId: 'volunteer-1', status: 'ACCEPTED'})
        }));
        expect(result).toEqual(updated);
        expect(prismaMock.deliveryTracking.create).toHaveBeenCalled();
    });

    it('rejects acceptance by a different volunteer for assigned deliveries', async () => {
        prismaMock.delivery.findUnique.mockResolvedValue(
            baseDelivery({volunteerId: 'other-volunteer', status: 'ASSIGNED'})
        );

        await expect(acceptDelivery('delivery-1', 'volunteer-1')).rejects.toThrow(
            'You are not assigned to this delivery.'
        );
        expect(prismaMock.delivery.update).not.toHaveBeenCalled();
    });

    it('enforces the accepted to delivered status workflow', async () => {
        prismaMock.delivery.findUnique.mockResolvedValue(
            baseDelivery({volunteerId: 'volunteer-1', status: 'ACCEPTED'})
        );
        prismaMock.delivery.update.mockResolvedValue(
            baseDelivery({volunteerId: 'volunteer-1', status: 'PICKED_UP'})
        );
        prismaMock.deliveryTracking.create.mockResolvedValue({});

        await updateDeliveryStatus('delivery-1', 'volunteer-1', 'PICKED_UP' as any);
        expect(prismaMock.delivery.update).toHaveBeenCalled();

        prismaMock.delivery.findUnique.mockResolvedValue(
            baseDelivery({volunteerId: 'volunteer-1', status: 'PICKED_UP'})
        );
        prismaMock.delivery.update.mockResolvedValue(
            baseDelivery({volunteerId: 'volunteer-1', status: 'IN_TRANSIT'})
        );
        await updateDeliveryStatus('delivery-1', 'volunteer-1', 'IN_TRANSIT' as any);

        prismaMock.delivery.findUnique.mockResolvedValue(
            baseDelivery({volunteerId: 'volunteer-1', status: 'IN_TRANSIT'})
        );
        prismaMock.delivery.update.mockResolvedValue(
            baseDelivery({volunteerId: 'volunteer-1', status: 'DELIVERED'})
        );
        await updateDeliveryStatus('delivery-1', 'volunteer-1', 'DELIVERED' as any);
    });

    it('orders optimized routes by expiry and includes a maps URL', async () => {
        prismaMock.delivery.findMany.mockResolvedValue([
            baseDelivery({id: 'later', foodExpiryDate: new Date('2026-09-06T12:00:00Z')}),
            baseDelivery({id: 'sooner', foodExpiryDate: new Date('2026-09-05T12:00:00Z')})
        ]);

        const result = await getOptimizedDeliveryRoute('volunteer-1');

        expect(result.route.map(delivery => delivery.id)).toEqual(['sooner', 'later']);
        expect(result.totalDistanceKm).toBeGreaterThan(0);
        expect(result.googleMapsUrl).toContain('google.com/maps/dir');
    });

    it('calculates dashboard impact statistics', async () => {
        prismaMock.delivery.findMany.mockResolvedValue([
            baseDelivery({status: 'DELIVERED', foodQuantityKg: 4}),
            baseDelivery({id: 'active', status: 'IN_TRANSIT', foodQuantityKg: 2})
        ]);

        await expect(getVolunteerDashboardStats('volunteer-1')).resolves.toMatchObject({
            completedDeliveries: 1,
            activeDeliveries: 1,
            totalFoodDeliveredKg: 4,
            communityImpactScore: 14
        });
    });

    it('records location and reported problems for an accessible delivery', async () => {
        prismaMock.delivery.findUnique.mockResolvedValue(
            baseDelivery({volunteerId: 'volunteer-1', status: 'ACCEPTED'})
        );
        prismaMock.deliveryTracking.create.mockResolvedValue({id: 'tracking-1'});
        prismaMock.deliveryProblem.create.mockResolvedValue({id: 'problem-1'});

        await updateVolunteerLocation('delivery-1', 'volunteer-1', {latitude: 6.9, longitude: 79.8});
        await reportDeliveryProblem('delivery-1', 'volunteer-1', {
            problemType: 'vehicle', description: 'Flat tyre'
        });

        expect(prismaMock.deliveryTracking.create).toHaveBeenCalled();
        expect(prismaMock.deliveryProblem.create).toHaveBeenCalled();
    });

    it('rejects an assigned delivery and stores its reason', async () => {
        prismaMock.delivery.findUnique.mockResolvedValue(
            baseDelivery({volunteerId: 'volunteer-1', status: 'ASSIGNED'})
        );
        prismaMock.delivery.update.mockResolvedValue(baseDelivery({status: 'REJECTED'}));
        prismaMock.deliveryTracking.create.mockResolvedValue({});

        await rejectDelivery('delivery-1', 'volunteer-1', 'No vehicle');

        expect(prismaMock.delivery.update).toHaveBeenCalledWith(expect.objectContaining({
            data: expect.objectContaining({status: 'REJECTED', rejectionReason: 'No vehicle'})
        }));
    });
});
